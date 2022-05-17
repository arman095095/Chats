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

final class MessageModel: MessageModelProtocol {
    
    var senderID: String
    var adressID: String
    var date: Date
    var id: String
    var firstOfDate: Bool
    var status: Status?
    var type: MessageContentType
    
    init(senderID: String,
         adressID: String,
         date: Date,
         id: String,
         firstOfDate: Bool,
         status: Status,
         type: MessageContentType) {
        self.senderID = senderID
        self.adressID = adressID
        self.date = date
        self.id = id
        self.firstOfDate = firstOfDate
        self.status = status
        self.type = type
    }
    
    init?(model: MessageNetworkModelProtocol) {
        guard let date = model.date else { return nil }
        self.senderID = model.senderID
        self.adressID = model.adressID
        self.date = date
        self.id = model.id
        self.firstOfDate = false
        self.status = Status(rawValue: model.status.rawValue)
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
    
    init?(message: Message?) {
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
        if let status = message.status {
            self.status = Status(rawValue: status)
        }
        self.adressID = adressID
        self.senderID = senderID
        self.id = id
        self.date = date
        self.firstOfDate = message.firstOfDate
    }
}
