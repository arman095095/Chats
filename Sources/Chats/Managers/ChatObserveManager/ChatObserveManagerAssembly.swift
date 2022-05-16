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

final class ChatObserveManagerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ChatObserveManagerProtocol.self) { r in
            guard let messagingService = r.resolve(MessagingServiceProtocol.self),
                  let coreDataService = r.resolve(CoreDataServiceProtocol.self),
                  let quickAccessManager = r.resolve(QuickAccessManagerProtocol.self),
                  let accountID = quickAccessManager.userID else { fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return ChatObserveManager(messagingService: messagingService,
                               coreDataService: coreDataService,
                               accountID: accountID)
        }.inObjectScope(.weak)
    }
}
