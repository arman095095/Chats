//
//  MessangerViewTextCustomCell.swift
//  diffibleData
//
//  Created by Arman Davidoff on 10.12.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import MessageKit
import Foundation
import DesignSystem
import UIKit

open class TextMessageCellCustom: TextMessageCell {
    
    private var dt: DateFormatter = {
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        dt.dateFormat = "HH:mm"
        return dt
    }()

    private var messageInfoViewSended = MessageInfoView(type: .sender(.text))
    private var messageInfoViewRecieved = MessageInfoView(type: .recieved(.text))
    
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            setupContraintsFromCurrentUser(attributes: attributes)
            setupContraintsFromNoCurrentUser(attributes: attributes)
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        messageInfoViewSended.removeAnimationFromSendStatusImage()
        messageInfoViewRecieved.removeAnimationFromSendStatusImage()
        messageInfoViewSended.sendStatusImageView.image = nil
        messageInfoViewRecieved.sendStatusImageView.image = nil
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(messageInfoViewSended)
        messageContainerView.addSubview(messageInfoViewRecieved)
        messageInfoViewRecieved.translatesAutoresizingMaskIntoConstraints = false
        messageInfoViewSended.translatesAutoresizingMaskIntoConstraints = false
    }
    
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let messageModel = message as? MessageCellViewModelProtocol else { return }
        let viewModel = TextMessageViewModel(message: messageModel)
        super.configure(with: viewModel, at: indexPath, and: messagesCollectionView)
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate,
              let dataSource = messagesCollectionView.messagesDataSource else { fatalError() }
        
        if dataSource.isFromCurrentSender(message: viewModel) {
            messageInfoViewSended.dateLabel.text = dt.string(from: message.sentDate)
            messageInfoViewSended.dateLabel.textColor = displayDelegate.textColor(for: viewModel, at: indexPath, in: messagesCollectionView)
            configureFromCurrentUser(message: message)
        } else {
            messageInfoViewRecieved.dateLabel.text = dt.string(from: message.sentDate)
            messageInfoViewRecieved.dateLabel.textColor = displayDelegate.textColor(for: viewModel, at: indexPath, in: messagesCollectionView)
            configureFromNoCurrentUser()
        }
    }
}

//MARK: Help
private extension TextMessageCellCustom {
    
    func configureFromCurrentUser(message: MessageType) {
        messageInfoViewRecieved.isHidden = true
        messageInfoViewSended.isHidden = false
        guard let status = (message as? MessageCellViewModelProtocol)?.sendingStatus else { return }
        messageInfoViewSended.status = status
    }
    
    func configureFromNoCurrentUser() {
        messageInfoViewSended.isHidden = true
        messageInfoViewRecieved.isHidden = false
    }
    
    func setupContraintsFromCurrentUser(attributes: MessagesCollectionViewLayoutAttributes) {
        messageInfoViewSended.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -14).isActive = true
        messageInfoViewSended.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -attributes.messageLabelInsets.top).isActive = true
        messageInfoViewSended.heightAnchor.constraint(equalToConstant: 8).isActive = true
        messageInfoViewSended.widthAnchor.constraint(equalToConstant: 41).isActive = true
    }
    
    func setupContraintsFromNoCurrentUser(attributes: MessagesCollectionViewLayoutAttributes) {
        messageInfoViewRecieved.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -14).isActive = true
        messageInfoViewRecieved.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -attributes.messageLabelInsets.top).isActive = true
        messageInfoViewRecieved.heightAnchor.constraint(equalToConstant: 8).isActive = true
        messageInfoViewRecieved.widthAnchor.constraint(equalToConstant: 30).isActive = true
    }
}
