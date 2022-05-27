//
//  File.swift
//  
//
//  Created by Арман Чархчян on 15.05.2022.
//

import Foundation
import ChatsRouteMap
import NetworkServices
import Services
import Utils

enum MessagesSocketsKeys: String {
    case typing
    case edited
    case new
}

protocol MessagingRecieveDelegate: AnyObject {
    func newMessagesRecieved(friendID: String, messages: [MessageModelProtocol])
    func messagesLooked(friendID: String)
    func typing(friendID: String, _ value: Bool)
}

protocol MessagingRecieveManagerProtocol {
    func addDelegate(_ delegate: MessagingRecieveDelegate)
    func removeDelegate<T>(_ delegate: T)
    func observeNewMessages(friendID: String)
    func observeLookedMessages(friendID: String)
    func observeTypingStatus(friendID: String)
    func getMessages(chats: [ChatModelProtocol], completion: @escaping ([ChatModelProtocol]) -> ())
}

final class MessagingRecieveManager {
    private let messagingService: MessagingNetworkServiceProtocol
    private let accountID: String
    private let coreDataService: CoreDataServiceProtocol
    private let queue: DispatchQueueProtocol
    private var sockets = [String: SocketProtocol]()
    private var multicastDelegates = MulticastDelegates<MessagingRecieveDelegate>()
    
    init(messagingService: MessagingNetworkServiceProtocol,
         coreDataService: CoreDataServiceProtocol,
         queue: DispatchQueueProtocol,
         accountID: String) {
        self.messagingService = messagingService
        self.accountID = accountID
        self.coreDataService = coreDataService
        self.queue = queue
    }
    
    deinit {
        sockets.values.forEach { $0.remove() }
    }
}

extension MessagingRecieveManager: MessagingRecieveManagerProtocol {
    
    func addDelegate(_ delegate: MessagingRecieveDelegate) {
        multicastDelegates.add(delegate: delegate)
    }
    
    func removeDelegate<T>(_ delegate: T) {
        multicastDelegates.remove(delegate: delegate)
    }
    
    func getMessages(chats: [ChatModelProtocol], completion: @escaping ([ChatModelProtocol]) -> ()) {
        var refreshedChats = [ChatModelProtocol]()
        let group = DispatchGroup()
        guard !chats.isEmpty else {
            completion(chats)
            return
        }
        queue.async {
            chats.forEach { chat in
                let cacheService = MessagesCacheService(accountID: self.accountID,
                                                        friendID: chat.friendID,
                                                        coreDataService: self.coreDataService)
                group.enter()
                self.messagingService.getMessages(from: self.accountID,
                                                  friendID: chat.friendID,
                                                  lastDate: cacheService.lastMessage?.date) { [weak self] result in
                    guard let self = self else { return }
                    defer { group.leave() }
                    switch result {
                    case .success(let messages):
                        messages.sorted(by: { $0.date! < $1.date! }).forEach {
                            guard let model = MessageModel(model: $0) else { return }
                            switch model.status {
                            case .sended, .waiting, .looked, .none:
                                model.firstOfDate = self.isFirstToday(friendID: model.adressID,
                                                                      date: model.date,
                                                                      messageID: model.id)
                            case .incomingNew, .incoming:
                                model.firstOfDate = self.isFirstToday(friendID: model.senderID,
                                                                      date: model.date,
                                                                      messageID: model.id)
                            }
                            switch $0.status {
                            case .sended:
                                cacheService.storeSendedMessage(model)
                            case .looked:
                                cacheService.storeLookedMessage(model)
                            case .incomingNew:
                                cacheService.storeNewIncomingMessage(model)
                            case .incoming:
                                cacheService.storeIncomingMessage(model)
                            }
                        }
                        chat.messages = cacheService.storedMessages
                        chat.newMessages = cacheService.storedNewMessages
                        chat.notSendedMessages = cacheService.storedNotSendedMessages
                        refreshedChats.append(chat)
                    case .failure:
                        break
                    }
                }
            }
            group.notify(queue: .main) {
                completion(refreshedChats)
            }
        }
    }
    
    func observeNewMessages(friendID: String) {
        let lastMessageDateHandler: ((String) -> Date?) = { [weak self] friendID in
            guard let self = self else { return nil }
            let cacheService = MessagesCacheService(accountID: self.accountID,
                                                    friendID: friendID,
                                                    coreDataService: self.coreDataService)
            return cacheService.lastMessage?.date
        }
        let socket = messagingService.initNewMessagesSocket(lastMessageDate: lastMessageDateHandler,
                                                            accountID: accountID,
                                                            from: friendID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messageModels):
                self.queue.async {
                    let cacheService = MessagesCacheService(accountID: self.accountID,
                                                            friendID: friendID,
                                                            coreDataService: self.coreDataService)
                    let messages: [MessageModelProtocol] = messageModels.sorted(by: { $0.date! < $1.date! }).compactMap {
                        guard let model = MessageModel(model: $0) else { return nil }
                        switch model.status {
                        case .sended, .waiting, .looked, .none:
                            model.firstOfDate = self.isFirstToday(friendID: model.adressID,
                                                                  date: model.date, messageID:
                                                                    model.id)
                        case .incomingNew, .incoming:
                            model.firstOfDate = self.isFirstToday(friendID: model.senderID,
                                                                  date: model.date,
                                                                  messageID: model.id)
                        }
                        switch $0.status {
                        case .sended:
                            cacheService.storeSendedMessage(model)
                        case .looked:
                            cacheService.storeLookedMessage(model)
                        case .incomingNew:
                            cacheService.storeNewIncomingMessage(model)
                        case .incoming:
                            cacheService.storeIncomingMessage(model)
                        }
                        return model
                    }
                    guard !messages.isEmpty else { return }
                    self.multicastDelegates.delegates.forEach { delegate in
                        DispatchQueue.main.async {
                            delegate.newMessagesRecieved(friendID: friendID, messages: messages)
                        }
                    }
                }
            case .failure:
                break
            }
        }
        sockets[MessagesSocketsKeys.new.rawValue + friendID] = socket
    }
    
    func observeLookedMessages(friendID: String) {
        let cacheService = MessagesCacheService(accountID: accountID,
                                                friendID: friendID,
                                                coreDataService: coreDataService)
        let socket = messagingService.initLookedMessagesSocket(accountID: accountID, from: friendID) { [weak self] result in
            switch result {
            case .success:
                self?.queue.async {
                    let notLooked = cacheService.storedNotLookedMessages
                    notLooked.forEach {
                        $0.status = .looked
                        cacheService.update($0)
                    }
                    cacheService.removeAllNotLooked()
                    DispatchQueue.main.async {
                        self?.multicastDelegates.delegates.forEach { delegate in
                            delegate.messagesLooked(friendID: friendID)
                        }
                    }
                }
            case .failure:
                break
            }
        }
        sockets[MessagesSocketsKeys.edited.rawValue] = socket
    }
    
    func observeTypingStatus(friendID: String) {
        let socket = messagingService.initTypingStatusSocket(from: accountID, friendID: friendID) { [weak self] typing in
            guard let typing = typing else { return }
            self?.multicastDelegates.delegates.forEach { delegate in
                delegate.typing(friendID: friendID, typing)
            }
        }
        sockets[MessagesSocketsKeys.typing.rawValue] = socket
    }
    
    func isFirstToday(friendID: String, date: Date, messageID: String) -> Bool {
        let cacheService = MessagesCacheService(accountID: accountID,
                                                friendID: friendID,
                                                coreDataService: coreDataService)
        guard let lastMessage = cacheService.lastMessage else { return true }
        if lastMessage.id == messageID {
            return lastMessage.firstOfDate
        }
        let messageDate = DateFormatService().getLocaleDate(date: date)
        let lastMessageDate = DateFormatService().getLocaleDate(date: lastMessage.date)
        return !(lastMessageDate.day == messageDate.day && lastMessageDate.month == messageDate.month && lastMessageDate.year == messageDate.year)
    }
}
