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
        container.register(ChatsRouteMap.self) { r in
            ChatsUserStory(container: container)
        }
    }
}
