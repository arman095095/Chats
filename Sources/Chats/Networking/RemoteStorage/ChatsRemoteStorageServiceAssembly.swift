//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import Swinject
import FirebaseStorage

final class ChatsRemoteStorageServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ChatsRemoteStorageServiceProtocol.self) { r in
            ChatsRemoteStorageService(storage: Storage.storage())
        }
    }
}
