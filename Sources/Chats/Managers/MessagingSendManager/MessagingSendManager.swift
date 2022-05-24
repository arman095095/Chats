//
//  File.swift
//  
//
//  Created by Арман Чархчян on 13.05.2022.
//

import Foundation
import NetworkServices
import ModelInterfaces
import Services
import Utils

protocol MessagingSendManagerProtocol: AnyObject {
    var cachedMessages: [MessageModelProtocol] { get }
    func readNewMessages()
    func sendDidBeganTyping()
    func sendDidFinishTyping()
    func sendTextMessage(_ content: String,
                         completion: @escaping (Result<MessageModelProtocol, Error>) -> ())
    func sendAudioMessage(_ localURL: String,
                          duration: Float,
                          completion: @escaping (Result<MessageModelProtocol, Error>) -> ())
    func sendPhotoMessage(_ data: Data,
                          ratio: Double,
                          completion: @escaping (Result<MessageModelProtocol, Error>) -> ())
    func sendAllWaitingMessages()
}

final class MessagingSendManager {
    
    private let accountID: String
    private let account: AccountModelProtocol
    private let friendID: String
    private let messagingService: MessagingNetworkServiceProtocol
    private let cacheService: MessagesCacheServiceProtocol
    private let remoteStorageService: ChatsRemoteStorageServiceProtocol
    
    init(accountID: String,
         account: AccountModelProtocol,
         chatID: String,
         messagingService: MessagingNetworkServiceProtocol,
         cacheService: MessagesCacheServiceProtocol,
         remoteStorageService: ChatsRemoteStorageServiceProtocol) {
        self.accountID = accountID
        self.account = account
        self.friendID = chatID
        self.messagingService = messagingService
        self.cacheService = cacheService
        self.remoteStorageService = remoteStorageService
    }
}

extension MessagingSendManager: MessagingSendManagerProtocol {
    
    var cachedMessages: [MessageModelProtocol] {
        cacheService.storedMessages
    }
    
    func sendAllWaitingMessages() {
        cacheService.storedNotSendedMessages.forEach {
            switch $0.type {
            case .text(content: let content):
                sendWaitingTextMessage(message: $0, content: content)
            case .audio(url: let url, duration: let duration):
                sendWaitingAudioMessage(message: $0, localURL: url, duration: duration)
            case .image(url: let url, ratio: let ratio):
                sendWaitingPhotoMessage(message: $0, localURL: url, ratio: ratio)
            }
        }
    }
    
    func sendTextMessage(_ content: String, completion: @escaping (Result<MessageModelProtocol, Error>) -> ()) {
        let uuid = UUID().uuidString
        let date = Date()
        let message = MessageModel(senderID: accountID,
                                   adressID: friendID,
                                   date: date,
                                   id: uuid,
                                   firstOfDate: isFirstToday(date: date),
                                   status: .waiting,
                                   type: .text(content: content))
        cacheService.storeCreatedMessage(message)
        completion(.success(message))
        let model = MessageNetworkModel(audioURL: nil,
                                        photoURL: nil,
                                        adressID: friendID,
                                        senderID: accountID,
                                        content: content,
                                        imageRatio: nil,
                                        audioDuration: nil,
                                        id: uuid,
                                        date: date)
        self.sendMessage(model: model, message: message)
    }
    
    func sendAudioMessage(_ localURL: String, duration: Float, completion: @escaping (Result<MessageModelProtocol, Error>) -> ()) {
        let uuid = UUID().uuidString
        let date = Date()
        let message = MessageModel(senderID: accountID,
                                   adressID: friendID,
                                   date: date,
                                   id: uuid,
                                   firstOfDate: isFirstToday(date: date),
                                   status: .waiting,
                                   type: .audio(url: localURL, duration: duration))
        cacheService.storeCreatedMessage(message)
        completion(.success(message))
        let url = FileManager.getDocumentsDirectory().appendingPathComponent(localURL)
        guard let audioData = try? Data(contentsOf: url) else { return }

        remoteStorageService.uploadChat(audio: audioData) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let remoteURL):
                let model = MessageNetworkModel(audioURL: remoteURL,
                                                photoURL: nil,
                                                adressID: self.friendID,
                                                senderID: self.accountID,
                                                content: "",
                                                imageRatio: nil,
                                                audioDuration: duration,
                                                id: uuid,
                                                date: date)
                self.sendMessage(model: model, message: message)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendPhotoMessage(_ data: Data, ratio: Double, completion: @escaping (Result<MessageModelProtocol, Error>) -> ()) {
        let uuid = UUID().uuidString
        let localURL = uuid.appending(".jpeg")
        let date = Date()
    
        let url = FileManager.getDocumentsDirectory().appendingPathComponent(localURL)
        guard let _ = try? data.write(to: url) else { return }
    
        let message = MessageModel(senderID: accountID,
                                   adressID: friendID,
                                   date: date,
                                   id: uuid,
                                   firstOfDate: isFirstToday(date: date),
                                   status: .waiting,
                                   type: .image(url: localURL, ratio: ratio))
        cacheService.storeCreatedMessage(message)
        completion(.success(message))
        remoteStorageService.uploadChat(image: data) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let remoteURL):
                let model = MessageNetworkModel(audioURL: nil,
                                                photoURL: remoteURL,
                                                adressID: self.friendID,
                                                senderID: self.accountID,
                                                content: "",
                                                imageRatio: ratio,
                                                audioDuration: nil,
                                                id: uuid,
                                                date: date)
                self.sendMessage(model: model, message: message)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func readNewMessages() {
        let newMessages = cacheService.storedNewMessages
        let ids = newMessages.map { $0.id }
        newMessages.forEach {
            $0.status = .incoming
            cacheService.update($0)
        }
        cacheService.removeAllNewMessages()
        guard !newMessages.isEmpty else { return }
        messagingService.sendLookedMessages(from: accountID,
                                            for: friendID,
                                            messageIDs: ids) { _ in }
    }
    
    func sendDidBeganTyping() {
        messagingService.sendDidBeganTyping(from: accountID, friendID: friendID) { _ in }
    }
    
    func sendDidFinishTyping() {
        messagingService.sendDidFinishTyping(from: accountID, friendID: friendID) { _ in }
    }
}

private extension MessagingSendManager {
    
    func sendWaitingAudioMessage(message: MessageModelProtocol, localURL: String, duration: Float) {
        let url = FileManager.getDocumentsDirectory().appendingPathComponent(localURL)
        guard let data = try? Data(contentsOf: url) else { return }

        remoteStorageService.uploadChat(audio: data) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let remoteURL):
                let model = MessageNetworkModel(audioURL: remoteURL,
                                                photoURL: nil,
                                                adressID: message.adressID,
                                                senderID: message.senderID,
                                                content: "",
                                                imageRatio: nil,
                                                audioDuration: duration,
                                                id: message.id,
                                                date: message.date)
                self.sendMessage(model: model, message: message)
            case .failure:
                break
            }
        }
    }
    
    func sendWaitingTextMessage(message: MessageModelProtocol, content: String) {
        let model = MessageNetworkModel(audioURL: nil,
                                        photoURL: nil,
                                        adressID: message.adressID,
                                        senderID: message.senderID,
                                        content: content,
                                        imageRatio: nil,
                                        audioDuration: nil,
                                        id: message.id,
                                        date: message.date)
        self.sendMessage(model: model, message: message)
    }
    
    func sendWaitingPhotoMessage(message: MessageModelProtocol, localURL: String, ratio: Double) {
        let url = FileManager.getDocumentsDirectory().appendingPathComponent(localURL)
        guard let data = try? Data(contentsOf: url) else { return }
        remoteStorageService.uploadChat(image: data) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let remoteURL):
                let model = MessageNetworkModel(audioURL: nil,
                                                photoURL: remoteURL,
                                                adressID: message.adressID,
                                                senderID: message.senderID,
                                                content: "",
                                                imageRatio: ratio,
                                                audioDuration: nil,
                                                id: message.id,
                                                date: message.date)
                self.sendMessage(model: model, message: message)
            case .failure:
                break
            }
        }
    }
    
    func sendMessage(model: MessageNetworkModelProtocol,
                     message: MessageModelProtocol) {
        self.messagingService.send(message: model) { _ in }
    }
    
    func isFirstToday(date: Date) -> Bool {
        guard let lastMessage = cacheService.lastMessage else { return true }
        let messageDate = DateFormatService().getLocaleDate(date: date)
        let lastMessageDate = DateFormatService().getLocaleDate(date: lastMessage.date)
        return !(lastMessageDate.day == messageDate.day && lastMessageDate.month == messageDate.month && lastMessageDate.year == messageDate.year)
    }
}
