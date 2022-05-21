//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import Foundation
import Swinject
import Managers
import Services

final class MessagesCacheServiceAssembly {
    func assemble(container: Container, friendID: String) {
        container.register(MessagesCacheServiceProtocol.self, name: friendID) { r in
            guard let userID = r.resolve(QuickAccessManagerProtocol.self)?.userID,
                  let coreDataService = r.resolve(CoreDataServiceProtocol.self) else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return MessagesCacheService(accountID: userID,
                                        friendID: friendID,
                                        coreDataService: coreDataService)
        }.inObjectScope(.weak)
    }
}
