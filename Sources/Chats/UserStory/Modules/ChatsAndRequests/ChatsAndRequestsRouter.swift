//
//  ChatsAndRequestsRouter.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import ModelInterfaces

protocol ChatsAndRequestsRouterInput: AnyObject {
    func openProfileModule(profile: ProfileModelProtocol)
}

final class ChatsAndRequestsRouter {
    weak var transitionHandler: UIViewController?
}

extension ChatsAndRequestsRouter: ChatsAndRequestsRouterInput {
    func openProfileModule(profile: ProfileModelProtocol) {
    
    }
}
