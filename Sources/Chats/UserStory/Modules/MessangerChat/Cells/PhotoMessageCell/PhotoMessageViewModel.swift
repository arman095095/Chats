//
//  MockPhotoMessage.swift
//  diffibleData
//
//  Created by Arman Davidoff on 11.12.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import MessageKit
import Foundation

struct PhotoMessageViewModel: MessageType {
    
    private let message: MessageCellViewModelProtocol
    
    init(message: MessageCellViewModelProtocol) {
        self.message = message
    }
    
    var sender: SenderType {
        return message.sender
    }
    
    var messageId: String {
        message.messageId
    }
    
    var sentDate: Date {
        message.sentDate
    }
    
    var kind: MessageKind {
        let custom = message.kind
        switch custom {
        case .custom(let photoKind):
            let photo = photoKind as! MessageKind
            switch photo {
            case .photo(let photo):
                return .photo(photo)
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
}
