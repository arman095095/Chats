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

protocol MessagingRecieveDelegate: AnyObject {
    func newMessagesRecieved(friendID: String, messages: [MessageModelProtocol])
    func messagesLooked(friendID: String, _ value: Bool)
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
    private let messagingService: MessagingServiceProtocol
    private let accountID: String
    private let coreDataService: CoreDataServiceProtocol
    private var sockets = [SocketProtocol]()
    private var multicastDelegates = MulticastDelegates<MessagingRecieveDelegate>()
    
    init(messagingService: MessagingServiceProtocol,
         coreDataService: CoreDataServiceProtocol,
         accountID: String) {
        self.messagingService = messagingService
        self.accountID = accountID
        self.coreDataService = coreDataService
    }
    
    deinit {
        sockets.forEach { $0.remove() }
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
            let cachedService = ChatCacheService(accountID: accountID,
                                              friendID: chat.friendID,
                                              coreDataService: coreDataService)
            let cachedChat = cachedService.lastMessage
            group.enter()
            self.messagingService.getMessages(from: accountID,
                                              friendID: chat.friendID,
                                              lastDate: cachedChat?.date) { result in
                defer { group.leave() }
                switch result {
                case .success(let messages):
                    let models = messages.compactMap { MessageModel(model: $0) }
                    cachedService.storeMessages(models)
                    chat.messages = cachedService.messages
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
        let cacheService = ChatCacheService(accountID: accountID,
                                            friendID: friendID,
                                            coreDataService: coreDataService)
        let socket = messagingService.initMessagesSocket(lastMessageDate: cacheService.lastMessage?.date,
                                                         accountID: accountID,
                                                         from: friendID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let messageModels):
                let messages: [MessageModelProtocol] = messageModels.compactMap {
                    guard let message = MessageModel(model: $0) else { return nil }
                    cacheService.storeRecievedMessage(message)
                    return message
                }
                self.multicastDelegates.delegates.forEach { delegate in
                    delegate.newMessagesRecieved(friendID: friendID, messages: messages)
                }
            case .failure:
                break
            }
        }
        sockets.append(socket)
    }
    
    func observeLookedMessages(friendID: String) {
        let cacheService = ChatCacheService(accountID: accountID,
                                            friendID: friendID,
                                            coreDataService: coreDataService)
        let socket = messagingService.initLookedSendedMessagesSocket(accountID: accountID, from: friendID) { [weak self] looked in
            defer {
                self?.multicastDelegates.delegates.forEach { delegate in
                    delegate.messagesLooked(friendID: friendID, looked)
                }
            }
            guard looked else { return }
            cacheService.removeAllNotLooked()
        }
        sockets.append(socket)
    }
    
    func observeTypingStatus(friendID: String) {
        let socket = messagingService.initTypingStatusSocket(from: accountID, friendID: friendID) { typing in
            guard let typing = typing else { return }
            self.multicastDelegates.delegates.forEach { delegate in
                delegate.typing(friendID: friendID, typing)
            }
        }
        sockets.append(socket)
    }
}
