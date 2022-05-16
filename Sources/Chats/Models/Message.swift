//
//  File.swift
//  
//
//  Created by Арман Чархчян on 13.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices
import Services

public final class MessageModel: MessageModelProtocol {

    public var senderID: String
    public var adressID: String
    public var date: Date
    public var id: String
    public var firstOfDate: Bool
    public var sendingStatus: SendingStatus?
    public var type: MessageContentType
    
    public init(senderID: String,
                adressID: String,
                date: Date,
                id: String,
                firstOfDate: Bool,
                sendingStatus: SendingStatus,
                type: MessageContentType) {
        self.senderID = senderID
        self.adressID = adressID
        self.date = date
        self.id = id
        self.firstOfDate = firstOfDate
        self.sendingStatus = sendingStatus
        self.type = type
    }
    
    public init?(model: MessageNetworkModelProtocol) {
        guard let date = model.date else { return nil }
        self.senderID = model.senderID
        self.adressID = model.adressID
        self.date = date
        self.id = model.id
        self.firstOfDate = false
        self.sendingStatus = nil
        if let audioURL = model.audioURL,
           let duration = model.audioDuration {
            self.type = .audio(url: audioURL, duration: duration)
        } else if let photoURL = model.photoURL,
                  let ratio = model.imageRatio {
            self.type = .image(url: photoURL, ratio: ratio)
        } else {
            self.type = .text(content: model.content)
        }
    }
    
    public init?(message: Message?) {
        guard let message = message,
              let id = message.id,
              let date = message.date,
              let senderID = message.senderID,
              let adressID = message.adressID else { return nil }
        if let photoURL = message.photoURL {
            self.type = .image(url: photoURL, ratio: message.photoRatio)
        } else if let audioURL = message.audioURL {
            self.type = .audio(url: audioURL, duration: message.audioDuration)
        } else if let content = message.textContent {
            self.type = .text(content: content)
        } else {
            self.type = .text(content: "")
        }
        if let sendingStatus = message.sendingStatus {
            self.sendingStatus = SendingStatus(rawValue: sendingStatus)
        }
        self.adressID = adressID
        self.senderID = senderID
        self.id = id
        self.date = date
        self.firstOfDate = message.firstOfDate
    }
}
