//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices

protocol ChatManagerProtocol: AnyObject {
    func observeNewMessages(completion: @escaping (((String, [MessageModelProtocol])) -> ()))
}

final class ChatManager {
    private let accountID: String
    private let messagingService: MessagingServiceProtocol
    private let cacheService: ChatsCacheServiceProtocol
    private var sockets: [SocketProtocol] = []
}

extension ChatManager: ChatManagerProtocol {
    func observeNewMessages(completion: @escaping (((String, [MessageModelProtocol])) -> ())) {
        cacheService.storedChats.forEach { chat in
            let socket = self.messagingService.initMessagesSocket(lastMessageDate: chat.lastMessage?.date,
                                                                  accountID: accountID,
                                                                  from: chat.friendID) { result in
                switch result {
                case .success(let messages):
                    let messageModel = messages.map { MessageM }
                    completion((chat.friendID, messages))
                case .failure:
                    break
                }
            }
            sockets.append(socket)
        }
    }
}

