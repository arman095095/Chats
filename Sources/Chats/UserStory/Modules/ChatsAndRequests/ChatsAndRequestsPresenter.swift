//
//  ChatsAndRequestsPresenter.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit

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
    private let router: ChatsAndRequestsRouterInput
    private let interactor: ChatsAndRequestsInteractorInput
    private let chats: [ChatCellViewModelProtocol]?
    private let requests: [RequestCellViewModelProtocol]?
    
    init(router: ChatsAndRequestsRouterInput,
         interactor: ChatsAndRequestsInteractorInput) {
        self.router = router
        self.interactor = interactor
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsViewOutput {

    var title: String {
        stringFactory.title
    }
    
    func viewDidLoad() {
        view?.setupInitialState()
    }
    
    func selectChat(at indexPath: IndexPath) {
        
    }
    
    func selectRequest(at indexPath: IndexPath) {
        guard let request = requests?[indexPath.row] else { return }
        
    }
    
    func removeChat(at indexPath: IndexPath) {
        
    }
    
    func filteredChats(text: String) {
        
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsInteractorOutput {
    
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsModuleInput {
    
}
