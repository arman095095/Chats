//
//  File.swift
//  
//
//  Created by Арман Чархчян on 27.05.2022.
//

import Swinject
import Foundation

final class DispatchQueueWrapperAssembly: Assembly {
    func assemble(container: Container) {
        container.register(DispatchQueueProtocol.self) { r in
            let chatQueue = DispatchQueue(label: "chatsBackgroundQueue")
            return DispatchQueueWrapper(queue: chatQueue)
        }.inObjectScope(.weak)
    }
}
