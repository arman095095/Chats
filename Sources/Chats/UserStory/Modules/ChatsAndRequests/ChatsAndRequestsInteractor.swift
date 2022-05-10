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
    func initialLoad()
    func initObserve()
    func remove(chat: ChatModelProtocol)
}

protocol ChatsAndRequestsInteractorOutput: AnyObject {
    func successLoaded(_ chats: [ChatModelProtocol], _ requests: [RequestModelProtocol])
    func changed(newChats: [ChatModelProtocol], removed: [ChatModelProtocol])
    func changed(newRequests: [RequestModelProtocol], removed: [RequestModelProtocol])
    func failureLoad(message: String)
}

final class ChatsAndRequestsInteractor {
    
    weak var output: ChatsAndRequestsInteractorOutput?
    private let communicationManager: CommunicationManagerProtocol
    
    init(communicationManager: CommunicationManagerProtocol) {
        self.communicationManager = communicationManager
    }
}

extension ChatsAndRequestsInteractor: ChatsAndRequestsInteractorInput {

    func remove(chat: ChatModelProtocol) {
        communicationManager.remove(chat: chat)
    }
    
    func initObserve() {
        communicationManager.observeFriends { [weak self] newChats, removed in
            self?.output?.changed(newChats: newChats, removed: removed)
        }
        communicationManager.observeRequests { [weak self] newRequests, removed in
            self?.output?.changed(newRequests: newRequests, removed: removed)
        }
    }
    
    func initialLoad() {
        communicationManager.getChatsAndRequests { [weak self] result in
            switch result {
            case .success((let chats, let requests)):
                self?.output?.successLoaded(chats, requests)
            case .failure(let error):
                self?.output?.failureLoad(message: error.localizedDescription)
            }
        }
    }
}
