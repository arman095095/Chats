//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import Foundation
import Services
import MessageKit
import UIKit

extension MessageModel: MessageType {
    class Sender: SenderType {
        var senderId: String
        
        var displayName: String
        
        init(senderId: String, displayName: String) {
            self.senderId = senderId
            self.displayName = displayName
        }
    }

    public var sender: SenderType {
        return Sender(senderId: senderID, displayName: "")
    }
      
    public var messageId: String {
        return id
    }
      
    public var sentDate: Date {
        return date
    }
      
    public var kind: MessageKind {
        switch type {
        case .text(content: let content):
            return .custom(MessageKind.text(content))
        case .audio(url: let url, duration: let duration):
            guard let url = URL(string: url) else { return .text("") }
            return .custom(MessageKind.audio(Audio(url: url,
                                                   duration: duration)))
        case .image(url: let url, ratio: let ratio):
            guard let placeholder = UIImage(named: Constants.placeholderImageName,
                                            in: Bundle.module,
                                            with: nil) else { return .text("") }
            return .custom(MessageKind.photo(Photo(url: URL(string: url),
                                                   image: nil,
                                                   placeholderImage: placeholder,
                                                   size: Photo.imageSize(ratio: ratio))))
        }
    }
}
