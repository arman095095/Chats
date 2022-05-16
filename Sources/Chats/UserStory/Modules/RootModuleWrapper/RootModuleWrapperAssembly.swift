//
//  RootModuleWrapperAssembly.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Module
import ChatsRouteMap
import ModelInterfaces

enum ChatModuleFlow {
    case chatsAndRequests
    case messanger(chat: MessangerChatModelProtocol)
}

enum RootModuleWrapperAssembly {
    static func makeModule(routeMap: RouteMapPrivate, flow: ChatModuleFlow) -> ChatsModule {
        let wrapper = RootModuleWrapper(routeMap: routeMap, flow: flow)
        return ChatsModule(input: wrapper, view: wrapper.view()) {
            wrapper.output = $0
        }
    }
}
