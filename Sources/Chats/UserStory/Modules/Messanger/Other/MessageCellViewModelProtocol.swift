//
//  File.swift
//  
//
//  Created by Арман Чархчян on 13.05.2022.
//

import UIKit
import MessageKit

enum StatusInfo {
    case waiting
    case sended
    case looked
    case error
    
    var imageName: String {
        switch self {
        case .waiting:
            return "wait"
        case .sended:
            return "Sented1"
        case .looked:
            return "sended3"
        case .error:
            return "wait"
        }
    }
}

protocol MessageCellViewModelProtocol {
    var sender: SenderType { get }
    var messageId: String { get }
    var sentDate: Date { get }
    var content: String { get }
    var kind: MessageKind { get }
    var sendingStatus: StatusInfo? { get }
    var firstOfDate: Bool { get }
}
