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

public protocol ChatsRouteMap: AnyObject {
    func rootModule() -> ChatsModule
}

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
    func module() -> ModuleProtocol {
        let module =
        module.output = outputWrapper
        return module
    }
}

enum ErrorMessage: LocalizedError {
    case dependency
}
