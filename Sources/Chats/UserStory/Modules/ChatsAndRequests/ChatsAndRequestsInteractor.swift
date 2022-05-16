//
//  ChatsAndRequestsInteractor.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Managers
import ModelInterfaces

protocol ChatsAndRequestsInteractorInput: AnyObject {
    var cachedChats: [ChatModelProtocol] { get }
    var cachedRequests: [RequestModelProtocol] { get }
    func remoteLoad()
    func startObserve()
    func stopObserve()
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
    func profilesUpdated()
    func failureLoad(message: String)
}

final class ChatsAndRequestsInteractor {
    
    weak var output: ChatsAndRequestsInteractorOutput?
    private let chatsAndRequestsManager: ChatsAndRequestsManagerProtocol
    private let messagingRecieveManager: MessagingRecieveManagerProtocol
    
    init(chatsAndRequestsManager: ChatsAndRequestsManagerProtocol,
         messagingRecieveManager: MessagingRecieveManagerProtocol) {
        self.chatsAndRequestsManager = chatsAndRequestsManager
        self.messagingRecieveManager = messagingRecieveManager
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
    
    func remoteLoad() {
        chatsAndRequestsManager.getChatsAndRequests { [weak self] result in
            switch result {
            case .success((let chats, let requests)):
                self?.messagingRecieveManager.getMessages(chats: chats) { chats in
                    self?.output?.successLoaded(chats, requests)
                }
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
            self?.removeObservers(chats: removed)
        }
        chatsAndRequestsManager.observeRequests { [weak self] newRequests, removed in
            self?.output?.changed(newRequests: newRequests, removed: removed)
            self?.addObservers(newRequests: newRequests)
            self?.removeObservers(requests: removed)
        }
        chatsAndRequestsManager.observeFriendsAndRequestsProfiles { [weak self] in
            self?.output?.profilesUpdated()
        }
    }
    
    func stopObserve() {
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
    
    func messagesLooked(friendID: String, _ value: Bool) {
        guard value else { return }
        output?.messagesLookedAtChat(chatID: friendID)
    }
    
    func typing(friendID: String, _ value: Bool) {
        value ? output?.chatDidBeganTyping(chatID: friendID) : output?.chatDidFinishTyping(chatID: friendID)
    }
}

private extension ChatsAndRequestsInteractor {
    func addObservers(newChats: [ChatModelProtocol]) {
        newChats.forEach {
            chatsAndRequestsManager.addObserveFriendsAndRequestsProfiles(id: $0.friendID) { [weak self] in
                self?.output?.profilesUpdated()
            }
        }
        newChats.forEach {
            messagingRecieveManager.observeNewMessages(friendID: $0.friendID)
            messagingRecieveManager.observeLookedMessages(friendID: $0.friendID)
            messagingRecieveManager.observeTypingStatus(friendID: $0.friendID)
        }
    }
    
    func addObservers(newRequests: [RequestModelProtocol]) {
        newRequests.forEach {
            chatsAndRequestsManager.addObserveFriendsAndRequestsProfiles(id: $0.senderID) { [weak self] in
                self?.output?.profilesUpdated()
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
}
