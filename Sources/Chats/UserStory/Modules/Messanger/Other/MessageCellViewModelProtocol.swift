//
//  File.swift
//  
//
//  Created by Арман Чархчян on 13.05.2022.
//

import UIKit
import MessageKit

protocol MessageCellViewModelProtocol {
    var sender: SenderType { get }
    var messageId: String { get }
    var sentDate: Date { get }
    var content: String { get }
    var kind: MessageKind { get }
    var sendingStatus: StatusInfo? { get }
    var firstOfDate: Bool { get }
}
