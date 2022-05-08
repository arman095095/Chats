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

enum RootModuleWrapperAssembly {
    static func makeModule(routeMap: RouteMapPrivate) -> ChatsModule {
        let wrapper = RootModuleWrapper(routeMap: routeMap)
        return ChatsModule(input: wrapper, view: wrapper.view()) {
            wrapper.output = $0
        }
    }
}
