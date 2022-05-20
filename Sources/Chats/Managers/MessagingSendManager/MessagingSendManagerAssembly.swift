//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import Foundation
import Swinject
import Managers
import NetworkServices
import Services
import ModelInterfaces

final class MessagingSendManagerAssembly{
    func assemble(container: Container, chatID: String)  {
        container.register(MessagingSendManagerProtocol.self) { r in
            guard let userID = r.resolve(QuickAccessManagerProtocol.self)?.userID,
                  let account = r.resolve(AccountModelProtocol.self),
                  let messagingService = r.resolve(MessagingNetworkServiceProtocol.self),
                  let cacheService = r.resolve(MessagesCacheServiceProtocol.self),
                  let remoteStorageService = r.resolve(ChatsRemoteStorageServiceProtocol.self) else {
                fatalError(ErrorMessage.dependency.localizedDescription)
            }
            return MessagingSendManager(accountID: userID,
                                    account: account,
                                    chatID: chatID,
                                    messagingService: messagingService,
                                    cacheService: cacheService,
                                    remoteStorageService: remoteStorageService)
        }.inObjectScope(.weak)
    }
}
