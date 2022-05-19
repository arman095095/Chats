//
//  File.swift
//  
//
//  Created by Арман Чархчян on 15.05.2022.
//

import Foundation
import ModelInterfaces
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
    func messagesLooked(friendID: String, messages: [MessageModelProtocol])
    func typing(friendID: String, _ value: Bool)
}

protocol MessagingRecieveManagerProtocol {
    func addDelegate(_ delegate: MessagingRecieveDelegate)
    func removeDelegate<T>(_ delegate: T)
    func observeNewMessages(friendID: String)
    func observeEditedMessages(friendID: String)
    func observeTypingStatus(friendID: String)
    func getMessages(chats: [ChatModelProtocol], completion: @escaping ([ChatModelProtocol]) -> ())
}

final class MessagingRecieveManager {
    private let messagingService: MessagingServiceProtocol
    private let accountID: String
    private let coreDataService: CoreDataServiceProtocol
    private var sockets = [String: SocketProtocol]()
    private var multicastDelegates = MulticastDelegates<MessagingRecieveDelegate>()
    
    init(messagingService: MessagingServiceProtocol,
         coreDataService: CoreDataServiceProtocol,
         accountID: String) {
        self.messagingService = messagingService
        self.accountID = accountID
        self.coreDataService = coreDataService
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
        chats.forEach { chat in
            let cacheService = MessagesCacheService(accountID: accountID,
                                                    friendID: chat.friendID,
                                                    coreDataService: coreDataService)
            group.enter()
            self.messagingService.getMessages(from: accountID,
                                              friendID: chat.friendID,
                                              lastDate: cacheService.lastMessage?.date) { [weak self] result in
                guard let self = self else { return }
                defer { group.leave() }
                switch result {
                case .success(let messages):
                    messages.forEach {
                        guard let model = MessageModel(model: $0) else { return }
                        switch model.status {
                        case .sended, .waiting, .looked, .none:
                            model.firstOfDate = self.isFirstToday(friendID: model.adressID, date: model.date)
                        case .incomingNew, .incoming:
                            model.firstOfDate = self.isFirstToday(friendID: model.senderID, date: model.date)
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
                    refreshedChats.append(chat)
                case .failure:
                    break
                }
            }
            group.notify(queue: .main) {
                completion(refreshedChats)
            }
        }
    }
    
    func observeNewMessages(friendID: String) {
        let cacheService = MessagesCacheService(accountID: accountID,
                                                friendID: friendID,
                                                coreDataService: coreDataService)
        sockets[MessagesSocketsKeys.new.rawValue + friendID]?.remove()
        let socket = messagingService.initNewMessagesSocket(lastMessageDate: cacheService.lastMessage?.date,
                                                         accountID: accountID,
                                                         from: friendID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messageModels):
                let messages: [MessageModelProtocol] = messageModels.compactMap {
                    guard let model = MessageModel(model: $0) else { return nil }
                    switch model.status {
                    case .sended, .waiting, .looked, .none:
                        model.firstOfDate = self.isFirstToday(friendID: model.adressID, date: model.date)
                    case .incomingNew, .incoming:
                        model.firstOfDate = self.isFirstToday(friendID: model.senderID, date: model.date)
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
                self.multicastDelegates.delegates.forEach { delegate in
                    delegate.newMessagesRecieved(friendID: friendID, messages: messages)
                }
            case .failure:
                break
            }
        }
        sockets[MessagesSocketsKeys.new.rawValue + friendID] = socket
    }
    
    func observeEditedMessages(friendID: String) {
        let cacheService = MessagesCacheService(accountID: accountID,
                                                friendID: friendID,
                                                coreDataService: coreDataService)
        let socket = messagingService.initEditedMessagesSocket(accountID: accountID, from: friendID) { [weak self] result in
            switch result {
            case .success(let editedMessages):
                cacheService.removeAllNotLooked()
                self?.multicastDelegates.delegates.forEach { delegate in
                    delegate.messagesLooked(friendID: friendID, messages: editedMessages.compactMap { MessageModel(model: $0) })
                }
            case .failure:
                break
            }
        }
        sockets[MessagesSocketsKeys.edited.rawValue] = socket
    }
    
    func observeTypingStatus(friendID: String) {
        let socket = messagingService.initTypingStatusSocket(from: accountID, friendID: friendID) { typing in
            guard let typing = typing else { return }
            self.multicastDelegates.delegates.forEach { delegate in
                delegate.typing(friendID: friendID, typing)
            }
        }
        sockets[MessagesSocketsKeys.typing.rawValue] = socket
    }
    
    func isFirstToday(friendID: String, date: Date) -> Bool {
        let cacheService = MessagesCacheService(accountID: accountID,
                                                friendID: friendID,
                                                coreDataService: coreDataService)
        if cacheService.storedMessages.isEmpty {
            return true
        }
        guard let lastMessage = cacheService.lastMessage else {
            return true
        }
        let messageDate = DateFormatService().getLocaleDate(date: date)
        let lastMessageDate = DateFormatService().getLocaleDate(date: lastMessage.date)
        if !(lastMessageDate.day == messageDate.day && lastMessageDate.month == messageDate.month && lastMessageDate.year == messageDate.year) {
            return true
        }
        return false
    }
}
