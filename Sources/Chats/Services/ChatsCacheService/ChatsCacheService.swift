//
//  File.swift
//  
//
//  Created by Арман Чархчян on 15.05.2022.
//

import Foundation
import ModelInterfaces
import Services

public protocol ChatCacheServiceProtocol {
    var lastMessage: MessageModelProtocol? { get }
    func storeRecievedMessage(_ message: MessageModelProtocol)
    func removeAllNotLooked()
}

public final class ChatCacheService {
    private let chat: Chat?
    private let coreDataService: CoreDataServiceProtocol
    
    public init(accountID: String,
                friendID: String,
                coreDataService: CoreDataServiceProtocol) {
        self.coreDataService = coreDataService
        let account = coreDataService.model(Account.self, id: accountID)
        self.chat = account?.chats?.first(where: { ($0 as? Chat)?.friendID == friendID }) as? Chat
    }
}

extension ChatCacheService: ChatCacheServiceProtocol {
    public var lastMessage: MessageModelProtocol? {
        guard let messages = chat?.messages as? Set<Message> else { return nil }
        let sorted = messages.sorted(by: { $0.date! < $1.date! })
        return MessageModel(message: sorted.last)
    }
    
    public func storeRecievedMessage(_ message: MessageModelProtocol) {
        let messageObject = coreDataService.initModel(Message.self) { object in
            fillFields(message: object, model: message)
        }
        chat?.addToMessages(messageObject)
        coreDataService.saveContext()
    }
    
    public func removeAllNotLooked() {
        guard let notLooked = chat?.notLookedMessages else { return }
        chat?.removeFromNotLookedMessages(notLooked)
        guard let notLookedMessages = notLooked.allObjects as? [Message] else { return }
        notLookedMessages.forEach {
            $0.sendingStatus = SendingStatus.looked.rawValue
            coreDataService.saveContext()
        }
        coreDataService.saveContext()
    }
}

private extension ChatCacheService {
    func fillFields(message: Message, model: MessageModelProtocol) {
        message.id = model.id
        message.senderID = model.senderID
        message.adressID = model.adressID
        message.firstOfDate = model.firstOfDate
        message.sendingStatus = model.sendingStatus?.rawValue
        message.date = model.date
        switch model.type {
        case .text(content: let content):
            message.textContent = content
        case .audio(url: let url, duration: let duration):
            message.audioURL = url
            message.audioDuration = duration
        case .image(url: let url, ratio: let ratio):
            message.photoURL = url
            message.photoRatio = ratio
        }
    }
}
