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
    func newMessagesAtChat(chatID: String)
    func messagesLookedAtChat(chatID: String)
    func profilesUpdated()
    func failureLoad(message: String)
}

final class ChatsAndRequestsInteractor {
    
    weak var output: ChatsAndRequestsInteractorOutput?
    private let chatsAndRequestsManager: ChatsAndRequestsManagerProtocol
    private let chatsManager: ChatManagerProtocol
    
    init(chatsAndRequestsManager: ChatsAndRequestsManagerProtocol,
         chatsManager: ChatManagerProtocol) {
        self.chatsAndRequestsManager = chatsAndRequestsManager
        self.chatsManager = chatsManager
    }
}

extension ChatsAndRequestsInteractor: ChatsAndRequestsInteractorInput {
    
    var cachedChats: [ChatModelProtocol] {
        chatsAndRequestsManager.getChatsAndRequests().chats
    }
    
    var cachedRequests: [RequestModelProtocol] {
        chatsAndRequestsManager.getChatsAndRequests().requests
    }
    
    func remoteLoad() {
        chatsAndRequestsManager.getChatsAndRequests { [weak self] result in
            switch result {
            case .success((let chats, let requests)):
                self?.output?.successLoaded(chats, requests)
            case .failure(let error):
                self?.output?.failureLoad(message: error.localizedDescription)
            }
        }
    }
    
    func startObserve() {
        chatsManager.addDelegate(self)
        chatsAndRequestsManager.observeFriends { [weak self] newChats, removed in
            self?.output?.changed(newChats: newChats, removed: removed)
        }
        chatsAndRequestsManager.observeRequests { [weak self] newRequests, removed in
            self?.output?.changed(newRequests: newRequests, removed: removed)
        }
        chatsAndRequestsManager.observeFriendsAndRequestsProfiles { [weak self] in
            self?.output?.profilesUpdated()
        }
    }
    
    func stopObserve() {
        chatsManager.removeDelegate(self)
    }

    func remove(chat: ChatModelProtocol) {
        chatsAndRequestsManager.remove(chat: chat)
    }
}

extension ChatsAndRequestsInteractor: ChatManagerDelegate {
    func newMessagesRecieved(friendID: String, messages: [MessageModelProtocol]) {
        output?.newMessagesAtChat(chatID: friendID)
    }
    
    func messagesLooked(friendID: String, _ value: Bool) {
        guard value else { return }
        output?.messagesLookedAtChat(chatID: friendID)
    }
    
    func typing(friendID: String, _ value: Bool) {
        value ? output?.chatDidBeganTyping(chatID: friendID) : output?.chatDidFinishTyping(chatID: friendID)
    }
}
