//
//  ChatsUserStory.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import Swinject
import ChatsRouteMap
import Module
import Foundation
import AlertManager
import Managers
import UserStoryFacade
import ModelInterfaces
import ProfileRouteMap
import NetworkServices

public final class ChatsUserStory {
    private let container: Container
    private var outputWrapper: RootModuleWrapper?
    public init(container: Container) {
        self.container = container
    }
}

extension ChatsUserStory: ChatsRouteMap {
    public func chatsAndRequestsModule() -> ChatsModule {
        let module = RootModuleWrapperAssembly.makeModule(routeMap: self, flow: .chatsAndRequests)
        outputWrapper = module.input as? RootModuleWrapper
        return module
    }
    
    public func messangerModule(with chat: MessangerChatModelProtocol) -> ChatsModule {
        let module = RootModuleWrapperAssembly.makeModule(routeMap: self, flow: .messanger(chat: chat))
        outputWrapper = module.input as? RootModuleWrapper
        return module
    }
}

extension ChatsUserStory: RouteMapPrivate {
    
    func messangerModule(chat: MessangerChatModelProtocol) -> MessangerChatModule {
        MessagesCacheServiceAssembly().assemble(container: container, friendID: chat.friendID)
        MessagingSendManagerAssembly().assemble(container: container, chatID: chat.friendID)
        guard let remoteStorageService = container.synchronize().resolve(ChatsRemoteStorageServiceProtocol.self),
              let chatManager = container.synchronize().resolve(MessagingRecieveManagerProtocol.self),
              let messagingManager = container.synchronize().resolve(MessagingSendManagerProtocol.self),
              let cacheService = container.synchronize().resolve(MessagesCacheServiceProtocol.self),
              let userID = container.synchronize().resolve(QuickAccessManagerProtocol.self)?.userID else {
            fatalError(ErrorMessage.dependency.localizedDescription)
        }
        let module = MessangerChatAssembly.makeModule(messagingManager:messagingManager,
                                                    
                                                      cacheService: cacheService,
                                                      remoteStorage: remoteStorageService,
                                                      chat: chat,
                                                      chatManager: chatManager,
                                                      accountID: userID,
                                                      routeMap: self)
        return module
    }
    
    func profileModule(model: ProfileModelProtocol) -> ProfileModule {
        let safeResolver = container.synchronize()
        guard let profileUserStory = safeResolver.resolve(UserStoryFacadeProtocol.self)?.profileUserStory else { fatalError(ErrorMessage.dependency.localizedDescription) }
        let module = profileUserStory.someAccountModule(profile: model)
        return module
    }
    
    func chatsAndRequestsModule() -> ChatsAndRequestsModule {
        let safeResolver = container.synchronize()
        guard let alertManager = safeResolver.resolve(AlertManagerProtocol.self),
              let chatsAndRequestsManager = safeResolver.resolve(ChatsAndRequestsManagerProtocol.self),
              let messagingRecieveManager = safeResolver.resolve(MessagingRecieveManagerProtocol.self) else {
            fatalError(ErrorMessage.dependency.localizedDescription)
        }
        let module = ChatsAndRequestsAssembly.makeModule(chatsAndRequestsManager: chatsAndRequestsManager,
                                                         messagingRecieveManager: messagingRecieveManager,
                                                         alertManager: alertManager,
                                                         routeMap: self)
        module.output = outputWrapper
        return module
    }
}

enum ErrorMessage: LocalizedError {
    case dependency
}
