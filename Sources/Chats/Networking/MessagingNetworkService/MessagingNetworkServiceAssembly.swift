//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import FirebaseFirestore
import Swinject

final class MessagingNetworkServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(MessagingNetworkServiceProtocol.self) { r in
            MessagingNetworkService(networkService: Firestore.firestore())
        }
    }
}
