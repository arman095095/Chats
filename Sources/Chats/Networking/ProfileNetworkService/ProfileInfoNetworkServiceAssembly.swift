//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Swinject
import FirebaseFirestore

final class ProfileInfoNetworkServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ProfileInfoNetworkServiceProtocol.self) { r in
            ProfileInfoNetworkService(networkService: Firestore.firestore())
        }
    }
}
