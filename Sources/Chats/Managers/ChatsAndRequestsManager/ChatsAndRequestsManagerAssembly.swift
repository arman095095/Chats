//
//  File.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//

import Foundation
import Swinject
import Services
import Managers
import ModelInterfaces
import NetworkServices

final class ChatsAndRequestsManagerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ChatsAndRequestsManagerProtocol.self) { r in
            guard let accountID = r.resolve(QuickAccessManagerProtocol.self)?.userID,
                  let account = r.resolve(AccountModelProtocol.self),
                  let chatsAndRequestsCacheService = r.resolve(ChatsAndRequestsCacheServiceProtocol.self),
                  let accountCacheService = r.resolve(AccountCacheServiceProtocol.self),
                  let profileService = r.resolve(ProfileInfoNetworkServiceProtocol.self),
                  let requestsService = r.resolve(ChatsAndRequestsNetworkServiceProtocol.self),
                  let messagingService = r.resolve(MessagingNetworkServiceProtocol.self)  else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return ChatsAndRequestsManager(accountID: accountID,
                                           account: account,
                                           accountCacheService: accountCacheService,
                                           messagingService: messagingService,
                                           chatsAndRequestsCacheService: chatsAndRequestsCacheService,
                                           profileService: profileService,
                                           requestsService: requestsService)
        }.inObjectScope(.weak)
    }
}
