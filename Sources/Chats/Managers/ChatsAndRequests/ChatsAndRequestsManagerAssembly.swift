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
                  let accountService = r.resolve(AccountServiceProtocol.self),
                  let chatsAndRequestsCacheService = r.resolve(ChatsAndRequestsCacheServiceProtocol.self),
                  let accountCacheService = r.resolve(AccountCacheServiceProtocol.self),
                  let profileService = r.resolve(ProfilesServiceProtocol.self),
                  let requestsService = r.resolve(RequestsServiceProtocol.self) else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return ChatsAndRequestsManager(accountID: accountID,
                                           account: account,
                                           accountService: accountService,
                                           accountCacheService: accountCacheService,
                                           chatsAndRequestsCacheService: chatsAndRequestsCacheService,
                                           profileService: profileService,
                                           requestsService: requestsService)
        }
    }
}
