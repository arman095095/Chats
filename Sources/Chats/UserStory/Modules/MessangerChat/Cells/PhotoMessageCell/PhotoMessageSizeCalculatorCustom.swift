//
//  PhotoMessageSizeCalculatorCustom.swift
//  diffibleData
//
//  Created by Arman Davidoff on 11.12.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import MessageKit
import UIKit

class PhotoMessageSizeCalculatorCustom: MediaMessageSizeCalculator {
    
    func setup() {
        outgoingAvatarSize = .zero
        incomingAvatarSize = .zero
    }
    
    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let message = message as? MessageCellViewModelProtocol else { return .zero }
        let viewModel = PhotoMessageViewModel(message: message)
        return super.messageContainerSize(for: viewModel)
    }
}
