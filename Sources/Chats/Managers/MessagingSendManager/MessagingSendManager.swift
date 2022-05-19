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
                         completion: @escaping (Result<Void, Error>) -> ())
    func sendAudioMessage(_ localURL: String,
                          duration: Float,
                          completion: @escaping (Result<Void, Error>) -> ())
    func sendPhotoMessage(_ data: Data,
                          ratio: Double,
                          completion: @escaping (Result<Void, Error>) -> ())
}

final class MessagingSendManager {
    
    private let accountID: String
    private let account: AccountModelProtocol
    private let friendID: String
    private let messagingService: MessagingServiceProtocol
    private let cacheService: MessagesCacheServiceProtocol
    private let remoteStorageService: RemoteStorageServiceProtocol
    
    init(accountID: String,
         account: AccountModelProtocol,
         chatID: String,
         messagingService: MessagingServiceProtocol,
         cacheService: MessagesCacheServiceProtocol,
         remoteStorageService: RemoteStorageServiceProtocol) {
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
    
    func sendTextMessage(_ content: String, completion: @escaping (Result<Void, Error>) -> ()) {
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
        let model = MessageNetworkModel(audioURL: nil,
                                        photoURL: nil,
                                        adressID: friendID,
                                        senderID: accountID,
                                        content: content,
                                        imageRatio: nil,
                                        audioDuration: nil,
                                        id: uuid,
                                        date: date)
        self.sendPreparedMessage(model: model, message: message, completion: completion)
    }
    
    func sendAudioMessage(_ localURL: String, duration: Float, completion: @escaping (Result<Void, Error>) -> ()) {
        let uuid = UUID().uuidString
        let date = Date()
        let message = MessageModel(senderID: accountID,
                                   adressID: friendID,
                                   date: date, id: uuid,
                                   firstOfDate: isFirstToday(date: date),
                                   status: .waiting,
                                   type: .audio(url: localURL, duration: duration))
        cacheService.storeCreatedMessage(message)
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
                self.sendPreparedMessage(model: model, message: message, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendPhotoMessage(_ data: Data, ratio: Double, completion: @escaping (Result<Void, Error>) -> ()) {
        let uuid = UUID().uuidString
        let date = Date()
    
        let url = FileManager.getDocumentsDirectory().appendingPathComponent(uuid)
        guard let _ = try? data.write(to: url) else { return }
    
        let message = MessageModel(senderID: accountID,
                                   adressID: friendID,
                                   date: date,
                                   id: uuid,
                                   firstOfDate: isFirstToday(date: date),
                                   status: .waiting,
                                   type: .image(url: url.absoluteString, ratio: ratio))
        cacheService.storeCreatedMessage(message)
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
                self.sendPreparedMessage(model: model, message: message, completion: completion)
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
    
    func sendPreparedMessage(model: MessageNetworkModelProtocol,
                             message: MessageModelProtocol,
                             completion: @escaping (Result<Void, Error>) -> ()) {
        self.messagingService.send(message: model) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isFirstToday(date: Date) -> Bool {
        if cacheService.storedMessages.isEmpty {
            return true
        }
        guard let lastMessage = cacheService.lastMessage else {
            return true
        }
        let messageDate = DateFormatService().getLocaleDate(date: date)
        let lastMessageDate = DateFormatService().getLocaleDate(date: lastMessage.date)
        if !(lastMessageDate.day == messageDate.day && lastMessageDate.month == messageDate.month && lastMessageDate.year == messageDate.year) {
            return true
        }
        return false
    }
}
