//
//  RouteMapPrivate.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import ProfileRouteMap
import ModelInterfaces

protocol RouteMapPrivate: AnyObject {
    func chatsAndRequestsModule() -> ChatsAndRequestsModule
    func profileModule(model: ProfileModelProtocol) -> ProfileModule
}
