//
//  MessangerChatAssembly.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Module
import ModelInterfaces
import NetworkServices
import Managers
import MessageKit

typealias MessangerChatModule = Module<MessangerChatModuleInput, MessangerChatModuleOutput>

enum MessangerChatAssembly {
    static func makeModule(messagingManager: MessagingSendManagerProtocol,
                           cacheService: MessagesCacheServiceProtocol,
                           remoteStorage: RemoteStorageServiceProtocol,
                           chat: MessangerChatModelProtocol,
                           chatManager: MessagingRecieveManagerProtocol,
                           accountID: String,
                           routeMap: RouteMapPrivate) -> MessangerChatModule {
        let messageCollectionView = MessagesCollectionView()
        let router = MessangerChatRouter(routeMap: routeMap)
        let audioRecorder = AudioMessageRecorder()
        let audioPlayer = AudioMessagePlayer(messageCollectionView: messageCollectionView,
                                             remoteStorageService: remoteStorage,
                                             cacheService: cacheService)
        let interactor = MessangerChatInteractor(messagingManager: messagingManager,
                                                 chatManager: chatManager,
                                                 audioRecorder: audioRecorder,
                                                 audioPlayer: audioPlayer)
        let stringFactory = ChatsStringFactory()
        let presenter = MessangerChatPresenter(router: router,
                                               interactor: interactor,
                                               stringFactory: stringFactory,
                                               chat: chat,
                                               accountID: accountID)
        let view = MessangerChatViewController(output: presenter)
        interactor.output = presenter
        presenter.view = view
        router.transitionHandler = view
        view.messagesCollectionView = messageCollectionView
        return MessangerChatModule(input: presenter, view: view) {
            presenter.output = $0
        }
    }
}
