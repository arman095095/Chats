//
//  ChatsUserStoryAssembly.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import Swinject
import ChatsRouteMap

public final class ChatsUserStoryAssembly: Assembly {
    
    public init() { }

    public func assemble(container: Container) {
        AccountCacheServiceAssembly().assemble(container: container)
        ProfileInfoNetworkServiceAssembly().assemble(container: container)
        MessagingNetworkServiceAssembly().assemble(container: container)
        ChatsRemoteStorageServiceAssembly().assemble(container: container)
        ChatsAndRequestsNetworkServiceAssembly().assemble(container: container)
        ChatsAndRequestsCacheServiceAssembly().assemble(container: container)
        ChatsAndRequestsManagerAssembly().assemble(container: container)
        MessagingRecieveManagerAssembly().assemble(container: container)
        container.register(ChatsRouteMap.self) { r in
            ChatsUserStory(container: container)
        }
    }
}
