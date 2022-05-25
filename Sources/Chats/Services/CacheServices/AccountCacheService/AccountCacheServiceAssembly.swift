//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import Swinject
import Services
import Managers

final class AccountCacheServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(AccountCacheServiceProtocol.self) { r in
            guard let coreDataService = r.resolve(CoreDataServiceProtocol.self),
                  let userID = r.resolve(QuickAccessManagerProtocol.self)?.userID else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return AccountCacheService(coreDataService: coreDataService,
                                       accountID: userID)
        }
    }
}
