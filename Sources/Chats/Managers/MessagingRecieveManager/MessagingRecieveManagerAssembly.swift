//
//  File.swift
//  
//
//  Created by Арман Чархчян on 15.05.2022.
//

import Foundation
import Swinject
import NetworkServices
import Services
import Managers

final class MessagingRecieveManagerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(MessagingRecieveManagerProtocol.self) { r in
            guard let messagingService = r.resolve(MessagingNetworkServiceProtocol.self),
                  let coreDataService = r.resolve(CoreDataServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let accountID = quickAccessManager.userID else { fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return MessagingRecieveManager(messagingService: messagingService,
                               coreDataService: coreDataService,
                               accountID: accountID)
        }.inObjectScope(.weak)
    }
}
