//
//  ChatsAndRequestsInteractor.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Managers
import ChatsRouteMap
import ModelInterfaces
import Swinject

protocol ChatsAndRequestsInteractorInput: AnyObject {
    var cachedChats: [ChatModelProtocol] { get }
    var cachedRequests: [RequestModelProtocol] { get }
    func cachedChat(with id: String) -> ChatModelProtocol?
    func cachedRequest(with id: String) -> RequestModelProtocol?
    func initSendingManagers()
    func sendNotSendedMessages()
    func remoteLoad()
    func startObserve()
    func stopObserving()
    func remove(chat: ChatModelProtocol)
}

protocol ChatsAndRequestsInteractorOutput: AnyObject {
    func successLoaded(_ chats: [ChatModelProtocol], _ requests: [RequestModelProtocol])
    func changed(newChats: [ChatModelProtocol], removed: [ChatModelProtocol])
    func changed(newRequests: [RequestModelProtocol], removed: [RequestModelProtocol])
    func chatDidBeganTyping(chatID: String)
    func chatDidFinishTyping(chatID: String)
    func newMessagesAtChat(chatID: String, messages: [MessageModelProtocol])
    func messagesLookedAtChat(chatID: String)
    func profilesUpdated(with: ProfileModelProtocol)
    func chatProfileUpdated(with profile: ProfileModelProtocol, chatID: String)
    func requestProfileUpdated(with profile: ProfileModelProtocol, requestID: String)
    func failureLoad(message: String)
}

final class ChatsAndRequestsInteractor {
    
    weak var output: ChatsAndRequestsInteractorOutput?
    private let chatsAndRequestsManager: ChatsAndRequestsManagerProtocol
    private let messagingRecieveManager: MessagingRecieveManagerProtocol
    private let container: Container
    private var sendingManagers = [String: MessagingSendManagerProtocol]()
    
    init(chatsAndRequestsManager: ChatsAndRequestsManagerProtocol,
         messagingRecieveManager: MessagingRecieveManagerProtocol,
         container: Container) {
        self.chatsAndRequestsManager = chatsAndRequestsManager
        self.messagingRecieveManager = messagingRecieveManager
        self.container = container
    }
}

extension ChatsAndRequestsInteractor: ChatsAndRequestsInteractorInput {
    
    var cachedChats: [ChatModelProtocol] {
        let chats = chatsAndRequestsManager.getChatsAndRequests().chats
        let sorted = chats.sorted { chat1, chat2 in
            guard let date1 = chat1.lastMessage?.date,
                  let date2 = chat2.lastMessage?.date else { return true }
            return date1 < date2
        }
        return sorted
    }
    
    var cachedRequests: [RequestModelProtocol] {
        chatsAndRequestsManager.getChatsAndRequests().requests
    }
    
    func cachedChat(with id: String) -> ChatModelProtocol? {
        chatsAndRequestsManager
            .getChatsAndRequests()
            .chats
            .first(where: { $0.friendID == id })
    }
    
    func cachedRequest(with id: String) -> RequestModelProtocol? {
        cachedRequests.first(where: { $0.senderID == id })
    }
    
    func sendNotSendedMessages() {
        sendingManagers.values.forEach {
            $0.sendAllWaitingMessages()
        }
    }
    
    func initSendingManagers() {
        chatsAndRequestsManager.getChatsAndRequests().chats.forEach {
            addSendingManager(friendID: $0.friendID)
        }
    }
    
    func remoteLoad() {
        chatsAndRequestsManager.getChatsAndRequests { [weak self] result in
            switch result {
            case .success((let chats, let requests)):
                self?.messagingRecieveManager.getMessages(chats: chats) { chats in
                    self?.output?.successLoaded(chats, requests)
                }
                self?.addSendingManagers(chats: chats)
            case .failure(let error):
                self?.output?.failureLoad(message: error.localizedDescription)
            }
        }
    }
    
    func startObserve() {
        messagingRecieveManager.addDelegate(self)
        cachedChats.forEach {
            self.messagingRecieveManager.observeNewMessages(friendID: $0.friendID)
            self.messagingRecieveManager.observeLookedMessages(friendID: $0.friendID)
            self.messagingRecieveManager.observeTypingStatus(friendID: $0.friendID)
        }
        chatsAndRequestsManager.observeFriends { [weak self] newChats, removed in
            self?.output?.changed(newChats: newChats, removed: removed)
            self?.addObservers(newChats: newChats)
            self?.addSendingManagers(chats: newChats)
            self?.removeObservers(chats: removed)
            self?.removeSendingManagers(chats: removed)
        }
        chatsAndRequestsManager.observeRequests { [weak self] newRequests, removed in
            self?.output?.changed(newRequests: newRequests, removed: removed)
            self?.addObservers(newRequests: newRequests)
            self?.removeObservers(requests: removed)
        }
        chatsAndRequestsManager.observeFriendsAndRequestsProfiles { [weak self] profile in
            guard let profile = profile else { return }
            self?.output?.profilesUpdated(with: profile)
        }
    }
    
    func stopObserving() {
        messagingRecieveManager.removeDelegate(self)
    }

    func remove(chat: ChatModelProtocol) {
        chatsAndRequestsManager.remove(chat: chat)
    }
}

extension ChatsAndRequestsInteractor: MessagingRecieveDelegate {
    func newMessagesRecieved(friendID: String, messages: [MessageModelProtocol]) {
        output?.newMessagesAtChat(chatID: friendID, messages: messages)
    }
    
    func messagesLooked(friendID: String) {
        output?.messagesLookedAtChat(chatID: friendID)
    }
    
    func typing(friendID: String, _ value: Bool) {
        value ? output?.chatDidBeganTyping(chatID: friendID) : output?.chatDidFinishTyping(chatID: friendID)
    }
}

private extension ChatsAndRequestsInteractor {
    func addObservers(newChats: [ChatModelProtocol]) {
        newChats.forEach { chat in
            chatsAndRequestsManager.addObserveFriendsAndRequestsProfiles(id: chat.friendID) { [weak self] profile in
                guard let profile = profile else { return }
                self?.output?.chatProfileUpdated(with: profile, chatID: chat.friendID)
            }
        }
        newChats.forEach {
            messagingRecieveManager.observeNewMessages(friendID: $0.friendID)
            messagingRecieveManager.observeLookedMessages(friendID: $0.friendID)
            messagingRecieveManager.observeTypingStatus(friendID: $0.friendID)
        }
    }
    
    func addObservers(newRequests: [RequestModelProtocol]) {
        newRequests.forEach { request in
            chatsAndRequestsManager.addObserveFriendsAndRequestsProfiles(id: request.senderID) { [weak self] profile in
                guard let profile = profile else { return }
                self?.output?.requestProfileUpdated(with: profile, requestID: request.senderID)
            }
        }
    }
    
    func removeObservers(chats: [ChatModelProtocol]) {
        chats.forEach {
            chatsAndRequestsManager.removeObserveFriendsAndRequestsProfiles(id: $0.friendID)
        }
    }
    
    func removeObservers(requests: [RequestModelProtocol]) {
        requests.forEach {
            chatsAndRequestsManager.removeObserveFriendsAndRequestsProfiles(id: $0.senderID)
        }
    }
    
    func addSendingManagers(chats: [ChatModelProtocol]) {
        chats.forEach {
            guard !sendingManagers.keys.contains($0.friendID) else { return }
            addSendingManager(friendID: $0.friendID)
        }
    }
    
    func removeSendingManagers(chats: [ChatModelProtocol]) {
        chats.forEach {
            removeSendingManager(friendID: $0.friendID)
        }
    }
    
    func addSendingManager(friendID: String) {
        MessagesCacheServiceAssembly().assemble(container: container, friendID: friendID)
        MessagingSendManagerAssembly().assemble(container: container, chatID: friendID)
        guard let messagingSendManager = container.synchronize().resolve(MessagingSendManagerProtocol.self, name: friendID) else {
            fatalError(ErrorMessage.dependency.localizedDescription)
        }
        self.sendingManagers[friendID] = messagingSendManager
    }
    
    func removeSendingManager(friendID: String) {
        self.sendingManagers[friendID] = nil
    }
}
