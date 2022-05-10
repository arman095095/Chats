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
    
    init(routeMap: RouteMapPrivate) {
        self.routeMap = routeMap
    }

    func view() -> UIViewController {
        let module = routeMap.chatsAndRequestsModule()
        module.output = self
        return module.view
    }
}

extension RootModuleWrapper: ChatsModuleInput {
    
}

extension RootModuleWrapper: ChatsAndRequestsModuleOutput { }

extension RootModuleWrapper: ProfileModuleOutput {
    
}
