//
//  ChatsAndRequestsAssembly.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Module
import Managers
import AlertManager
import Swinject

typealias ChatsAndRequestsModule = Module<ChatsAndRequestsModuleInput, ChatsAndRequestsModuleOutput>

enum ChatsAndRequestsAssembly {
    static func makeModule(chatsAndRequestsManager: ChatsAndRequestsManagerProtocol,
                           messagingRecieveManager: MessagingRecieveManagerProtocol,
                           alertManager: AlertManagerProtocol,
                           routeMap: RouteMapPrivate,
                           container: Container) -> ChatsAndRequestsModule {
        let view = ChatsAndRequestsViewController()
        let router = ChatsAndRequestsRouter(routeMap: routeMap)
        let interactor = ChatsAndRequestsInteractor(chatsAndRequestsManager: chatsAndRequestsManager,
                                                    messagingRecieveManager: messagingRecieveManager,
                                                    container: container)
        let stringFactory = ChatsStringFactory()
        let presenter = ChatsAndRequestsPresenter(router: router,
                                                  interactor: interactor,
                                                  alertManager: alertManager,
                                                  stringFactory: stringFactory)
        view.output = presenter
        interactor.output = presenter
        presenter.view = view
        router.transitionHandler = view
        return ChatsAndRequestsModule(input: presenter, view: view) {
            presenter.output = $0
        }
    }
}
