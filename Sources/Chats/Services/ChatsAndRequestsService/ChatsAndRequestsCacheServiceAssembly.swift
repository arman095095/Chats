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

public final class ChatsAndRequestsCacheServiceAssembly: Assembly {
    
    public init() { }
    
    public func assemble(container: Container) {
        container.register(ChatsAndRequestsCacheServiceProtocol.self) { r in
            guard let coreDataService = r.resolve(CoreDataServiceProtocol.self),
                  let userID = r.resolve(QuickAccessManagerProtocol.self)?.userID
            else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return ChatsAndRequestsCacheService(accountID: userID, coreDataService: coreDataService)
        }.inObjectScope(.weak)
    }
}
