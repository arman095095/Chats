//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import Swinject
import FirebaseFirestore

final class ChatsAndRequestsNetworkServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ChatsAndRequestsNetworkServiceProtocol.self) { r in
            ChatsAndRequestsNetworkService(networkService: Firestore.firestore())
        }
    }
}
