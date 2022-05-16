//
//  MessangerChatRouter.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import ModelInterfaces

protocol MessangerChatRouterInput: AnyObject {
    func openProfileModule(profile: ProfileModelProtocol)
    func openImage(_ photo: UIImage)
}

final class MessangerChatRouter {
    weak var transitionHandler: UIViewController?
    private let routeMap: RouteMapPrivate
    
    init(routeMap: RouteMapPrivate) {
        self.routeMap = routeMap
    }
}

extension MessangerChatRouter: MessangerChatRouterInput {
    func openProfileModule(profile: ProfileModelProtocol) {
        let module = routeMap.profileModule(model: profile)
        self.transitionHandler?.navigationController?.pushViewController(module.view, animated: true)
    }
    
    func openImage(_ photo: UIImage) {
    
    }
}
