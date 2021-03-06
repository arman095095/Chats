//
//  ChatsAndRequestsRouter.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import ModelInterfaces
import ChatsRouteMap
import ProfileRouteMap

protocol ChatsAndRequestsRouterInput: AnyObject {
    func setupBadge(count: String?)
    func openProfileModule(profile: ProfileModelProtocol, output: ProfileModuleOutput)
    func openMessangerModule(chat: ChatModelProtocol, output: MessangerChatModuleOutput)
    func dismissProfileModule()
}

final class ChatsAndRequestsRouter {
    weak var transitionHandler: UIViewController?
    private let routeMap: RouteMapPrivate
    
    init(routeMap: RouteMapPrivate) {
        self.routeMap = routeMap
    }
}

extension ChatsAndRequestsRouter: ChatsAndRequestsRouterInput {

    func setupBadge(count: String?) {
        transitionHandler?.tabBarItem.badgeValue = count
    }
    
    func openProfileModule(profile: ProfileModelProtocol, output: ProfileModuleOutput) {
        let module = routeMap.profileModule(model: profile)
        module.output = output
        transitionHandler?.navigationController?.pushViewController(module.view, animated: true)
    }
    
    func openMessangerModule(chat: ChatModelProtocol, output: MessangerChatModuleOutput) {
        guard let chat = chat as? MessangerChatModelProtocol else { return }
        let module = routeMap.messangerModule(chat: chat)
        module.output = output
        transitionHandler?.navigationController?.pushViewController(module.view, animated: true)
    }
    
    func dismissProfileModule() {
        transitionHandler?.navigationController?.popViewController(animated: true)
    }
}
