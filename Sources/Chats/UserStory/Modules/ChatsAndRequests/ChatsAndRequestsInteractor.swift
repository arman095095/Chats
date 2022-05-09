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
    func getChats()
    func getRequests()
}

protocol ChatsAndRequestsInteractorOutput: AnyObject {
    func successChatsLoaded(_ chats: [ChatModelProtocol])
    func failureChatsLoad(message: String)
    func successRequestsLoaded(_ requests: [RequestModelProtocol])
    func failureRequestsLoad(message: String)
}

final class ChatsAndRequestsInteractor {
    
    weak var output: ChatsAndRequestsInteractorOutput?
    private let communicationManager: CommunicationManagerProtocol
    
    init(communicationManager: CommunicationManagerProtocol) {
        self.communicationManager = communicationManager
    }
}

extension ChatsAndRequestsInteractor: ChatsAndRequestsInteractorInput {
    func getChats() {
        communicationManager.getChats { [weak self] result in
            switch result {
            case .success(let chats):
                self?.output?.successChatsLoaded(chats)
            case .failure(let error):
                self?.output?.failureChatsLoad(message: error.localizedDescription)
            }
        }
    }
    
    func getRequests() {
        communicationManager.getRequests { [weak self] result in
            switch result {
            case .success(let requests):
                self?.output?.successRequestsLoaded(requests)
            case .failure(let error):
                self?.output?.failureRequestsLoad(message: error.localizedDescription)
            }
        }
    }
}
