//
//  ChatsAndRequestsPresenter.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import AlertManager
import ModelInterfaces
import Utils

protocol ChatsAndRequestsStringFactoryProtocol {
    var title: String { get }
}

protocol ChatsAndRequestsModuleOutput: AnyObject {
    
}

protocol ChatsAndRequestsModuleInput: AnyObject {
    
}

protocol ChatsAndRequestsViewOutput: AnyObject {
    var title: String { get }
    func viewDidLoad()
    func selectChat(at indexPath: IndexPath)
    func selectRequest(at indexPath: IndexPath)
    func removeChat(at indexPath: IndexPath)
    func filteredChats(text: String)
}

final class ChatsAndRequestsPresenter {
    
    weak var view: ChatsAndRequestsViewInput?
    weak var output: ChatsAndRequestsModuleOutput?
    private let stringFactory: ChatsAndRequestsStringFactoryProtocol
    private let alertManager: AlertManagerProtocol
    private let router: ChatsAndRequestsRouterInput
    private let interactor: ChatsAndRequestsInteractorInput
    private var chats: [ChatCellViewModelProtocol]
    private var requests: [RequestCellViewModelProtocol]
    
    init(router: ChatsAndRequestsRouterInput,
         interactor: ChatsAndRequestsInteractorInput,
         alertManager: AlertManagerProtocol,
         stringFactory: ChatsAndRequestsStringFactoryProtocol) {
        self.router = router
        self.interactor = interactor
        self.stringFactory = stringFactory
        self.alertManager = alertManager
        self.chats = []
        self.requests = []
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsViewOutput {
    
    var title: String {
        stringFactory.title
    }
    
    func viewDidLoad() {
        view?.setupInitialState()
        interactor.getChats()
        interactor.getRequests()
    }
    
    func selectChat(at indexPath: IndexPath) {
        
    }
    
    func selectRequest(at indexPath: IndexPath) {
        let request = requests[indexPath.row]
        
    }
    
    func removeChat(at indexPath: IndexPath) {
        
    }
    
    func filteredChats(text: String) {
        
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsInteractorOutput {
    func failureChatsLoad(message: String) {
        alertManager.present(type: .error, title: message)
    }
    
    func failureRequestsLoad(message: String) {
        alertManager.present(type: .error, title: message)
    }
    
    func successChatsLoaded(_ chats: [ChatModelProtocol]) {
        self.chats = chats.map { Item(id: $0.friendID,
                                      userName: $0.friend.userName,
                                      imageURL: $0.friend.imageUrl,
                                      lastMessageContent: "Напишите первое сообщение",
                                      lastMessageDate: DateFormatService().convertForActiveChat(from: Date()),
                                      lastMessageMarkedImage: UIImage(),
                                      online: true,
                                      newMessagesEnable: true,
                                      newMessagesCount: 2) }
        
        view?.reloadData(requests: requests, chats: chats)
    }
    
    func successRequestsLoaded(_ requests: [RequestModelProtocol]) {
        self.requests = requests.map { Item(id: $0.senderID,
                                            userName: $0.sender.userName,
                                            imageURL: $0.sender.imageUrl,
                                            lastMessageContent: "",
                                            lastMessageDate: DateFormatService().convertForActiveChat(from: Date()),
                                            lastMessageMarkedImage: UIImage(),
                                            online: true,
                                            newMessagesEnable: false,
                                            newMessagesCount: 0) }
        view?.reloadData(requests: requests, chats: chats)
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsModuleInput {
    
}
