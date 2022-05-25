//
//  File 2.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import ChatsRouteMap
import NetworkServices
import Services

final class RequestModel: RequestModelProtocol {
    var sender: ProfileModelProtocol
    var senderID: String
    
    init(sender: ProfileNetworkModelProtocol) {
        self.sender = ProfileModel(profile: sender)
        self.senderID = sender.id
    }
    
    init?(request: Request?) {
        guard let request = request,
              let senderID = request.senderID,
              let sender = request.sender,
              let profile = ProfileModel(profile: sender) else { return nil }
        self.senderID = senderID
        self.sender = profile
    }
}
