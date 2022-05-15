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
import MessangerRouteMap

public final class ChatsUserStory {
    private let container: Container
    private var outputWrapper: RootModuleWrapper?
    public init(container: Container) {
        self.container = container
    }
}

extension ChatsUserStory: ChatsRouteMap {
    public func rootModule() -> ChatsModule {
        let module = RootModuleWrapperAssembly.makeModule(routeMap: self)
        outputWrapper = module.input as? RootModuleWrapper
        return module
    }
}

extension ChatsUserStory: RouteMapPrivate {
    
    func messangerModule(chat: ChatModelProtocol) -> MessangerModule {
        let safeResolver = container.synchronize()
        guard let messangerUserStory = safeResolver.resolve(UserStoryFacadeProtocol.self)?.messangerUserStory else { fatalError(ErrorMessage.dependency.localizedDescription) }
        let module = messangerUserStory.rootModule(with: chat)
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
              let chatManager = safeResolver.resolve(ChatManagerProtocol.self) else {
            fatalError(ErrorMessage.dependency.localizedDescription)
        }
        let module = ChatsAndRequestsAssembly.makeModule(chatsAndRequestsManager: chatsAndRequestsManager,
                                                         chatsManager: chatManager,
                                                         alertManager: alertManager,
                                                         routeMap: self)
        module.output = outputWrapper
        return module
    }
}

enum ErrorMessage: LocalizedError {
    case dependency
}
