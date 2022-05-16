//
//  RootModuleWrapper.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Module
import ChatsRouteMap
import ProfileRouteMap

final class RootModuleWrapper {

    private let routeMap: RouteMapPrivate
    weak var output: ChatsModuleOutput?
    private let flow: ChatModuleFlow
    
    init(routeMap: RouteMapPrivate, flow: ChatModuleFlow) {
        self.routeMap = routeMap
        self.flow = flow
    }

    func view() -> UIViewController {
        switch flow {
        case .chatsAndRequests:
            let module = routeMap.chatsAndRequestsModule()
            module.output = self
            return module.view
        case .messanger(let chat):
            let module = routeMap.messangerModule(chat: chat)
            module.output = self
            return module.view
        }
    }
}

extension RootModuleWrapper: ChatsModuleInput {
    
}

extension RootModuleWrapper: MessangerChatModuleOutput { }

extension RootModuleWrapper: ChatsAndRequestsModuleOutput { }
