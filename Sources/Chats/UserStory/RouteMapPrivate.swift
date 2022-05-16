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
import MessangerRouteMap

protocol RouteMapPrivate: AnyObject {
    func chatsAndRequestsModule() -> ChatsAndRequestsModule
    func profileModule(model: ProfileModelProtocol) -> ProfileModule
    func messangerModule(chat: MessangerChatModelProtocol) -> MessangerChatModule
}
