//
//  File.swift
//
//
//  Created by Арман Чархчян on 14.05.2022.
//

import Foundation
import ModelInterfaces
import Services

protocol MessagesCacheServiceProtocol {
    var storedMessages: [MessageModelProtocol] { get }
    var storedNewMessages: [MessageModelProtocol] { get }
    var storedNotLookedMessages: [MessageModelProtocol] { get }
    var storedNotSendedMessages: [MessageModelProtocol] { get }
    var lastMessage: MessageModelProtocol? { get }
    var firstMessage: MessageModelProtocol? { get }
    func storeCreatedMessage(_ message: MessageModelProtocol)
    func storeSendedMessage(_ message: MessageModelProtocol)
    func storeLookedMessage(_ message: MessageModelProtocol)
    func storeIncomingMessage(_ message: MessageModelProtocol)
    func storeNewIncomingMessage(_ message: MessageModelProtocol)
    func update(_ message: MessageModelProtocol)
    func removeFromNotSended(message: MessageModelProtocol)
    func removeAllNotLooked()
    func removeAllNewMessages()
}

final class MessagesCacheService {

    private let chat: Chat?
    private let coreDataService: CoreDataServiceProtocol
    
    init(accountID: String,
         friendID: String,
         coreDataService: CoreDataServiceProtocol) {
        self.coreDataService = coreDataService
        let account = coreDataService.model(Account.self, id: accountID)
        self.chat = account?.chats?.first(where: { ($0 as? Chat)?.friendID == friendID }) as? Chat
    }
}

extension MessagesCacheService: MessagesCacheServiceProtocol {
    var storedNotSendedMessages: [MessageModelProtocol] {
        chat?.notSendedMessages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
    }
    
    var storedNewMessages: [MessageModelProtocol] {
        chat?.notReadMessages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
    }

    var storedMessages: [MessageModelProtocol] {
        guard let messages = chat?.messages as? Set<Message> else { return [] }
        let sorted = messages.sorted(by: { $0.date! < $1.date! })
        return sorted.compactMap { MessageModel(message: $0) }
    }
    
    var storedNotLookedMessages: [MessageModelProtocol] {
        chat?.notLookedMessages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
    }
    
    var lastMessage: MessageModelProtocol? {
        guard let messages = chat?.messages as? Set<Message> else { return nil }
        let sorted = messages.sorted(by: { $0.date! < $1.date! })
        return MessageModel(message: sorted.last)
    }
    
    var firstMessage: MessageModelProtocol? {
        guard let messages = chat?.messages as? Set<Message> else { return nil }
        let sorted = messages.sorted(by: { $0.date! < $1.date! })
        return MessageModel(message: sorted.first)
    }
    
    func storeIncomingMessage(_ message: MessageModelProtocol) {
        let object = coreDataService.initModel(Message.self) { mobject in
            fillFields(message: mobject, model: message)
        }
        chat?.addToMessages(object)
        coreDataService.saveContext()
    }
    
    func storeNewIncomingMessage(_ message: MessageModelProtocol) {
        let object = coreDataService.initModel(Message.self) { mobject in
            fillFields(message: mobject, model: message)
        }
        chat?.addToMessages(object)
        chat?.addToNotReadMessages(object)
        coreDataService.saveContext()
    }
    
    func storeLookedMessage(_ message: MessageModelProtocol) {
        guard let messageObject = chat?.messages?.first(where: { ($0 as? Message)?.id == message.id }) as? Message else {
            let object = coreDataService.initModel(Message.self) { mobject in
                fillFields(message: mobject, model: message)
            }
            chat?.addToMessages(object)
            coreDataService.saveContext()
            return
        }
        coreDataService.update(messageObject) { object in
            fillFields(message: object, model: message)
        }
        chat?.removeFromNotLookedMessages(messageObject)
        coreDataService.saveContext()
    }
    
    func storeSendedMessage(_ message: MessageModelProtocol) {
        guard let messageObject = chat?.messages?.first(where: { ($0 as? Message)?.id == message.id }) as? Message else {
            let object = coreDataService.initModel(Message.self) { mobject in
                fillFields(message: mobject, model: message)
            }
            chat?.removeFromNotSendedMessages(object)
            chat?.addToNotLookedMessages(object)
            chat?.addToMessages(object)
            coreDataService.saveContext()
            return
        }
        coreDataService.update(messageObject) { object in
            fillFields(message: object, model: message)
        }
        chat?.removeFromNotSendedMessages(messageObject)
        coreDataService.saveContext()
    }
    
    func storeCreatedMessage(_ message: MessageModelProtocol) {
        let messageObject = coreDataService.initModel(Message.self) { object in
            fillFields(message: object, model: message)
        }
        chat?.addToMessages(messageObject)
        chat?.addToNotSendedMessages(messageObject)
        chat?.addToNotLookedMessages(messageObject)
        coreDataService.saveContext()
    }
    
    func update(_ message: MessageModelProtocol) {
        guard let messageObject = chat?.messages?.first(where: { ($0 as? Message)?.id == message.id }) as? Message else { return }
        coreDataService.update(messageObject) { object in
            fillFields(message: messageObject, model: message)
        }
    }
    
    func removeFromNotSended(message: MessageModelProtocol) {
        guard let messageObject = chat?.notSendedMessages?.first(where: { ($0 as? Message)?.id == message.id }) as? Message else { return }
        coreDataService.update(messageObject) { object in
            fillFields(message: object, model: message)
        }
        chat?.removeFromNotSendedMessages(messageObject)
        coreDataService.saveContext()
    }
    
    func removeAllNotLooked() {
        guard let notLooked = chat?.notLookedMessages else { return }
        chat?.removeFromNotLookedMessages(notLooked)
        coreDataService.saveContext()
    }
    
    func removeAllNewMessages() {
        guard let newMessages = chat?.notReadMessages else { return }
        chat?.removeFromNotReadMessages(newMessages)
        coreDataService.saveContext()
    }
}

private extension MessagesCacheService {
    func fillFields(message: Message, model: MessageModelProtocol) {
        message.id = model.id
        message.senderID = model.senderID
        message.adressID = model.adressID
        message.firstOfDate = model.firstOfDate
        message.status = model.status?.rawValue
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
