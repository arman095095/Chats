//
//  AudioMessageCellCustom.swift
//  diffibleData
//
//  Created by Arman Davidoff on 11.12.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import MessageKit
import Foundation
import DesignSystem
import UIKit

open class AudioMessageCellCustom: AudioMessageCell {
    
    private var dt: DateFormatter = {
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        dt.dateFormat = "HH:mm"
        return dt
    }()
    
    public var activityIndicator: CustomActivityIndicator  = {
        let view = CustomActivityIndicator()
        view.lineWidth = 2
        view.strokeColor = UIColor.mainApp()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var messageInfoViewSended = MessageInfoView(type: .sender(.audio))
    private var messageInfoViewRecieved = MessageInfoView(type: .recieved(.audio))
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        messageInfoViewSended.removeAnimationFromSendStatusImage()
        messageInfoViewRecieved.removeAnimationFromSendStatusImage()
        messageInfoViewRecieved.sendStatusImageView.image = nil
        messageInfoViewSended.sendStatusImageView.image = nil
        messageInfoViewRecieved.sendStatusImageView.image = nil
        activityIndicator.completeLoading(success: true)
        activityIndicator.isHidden = true
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(messageInfoViewSended)
        messageContainerView.addSubview(messageInfoViewRecieved)
        messageContainerView.addSubview(activityIndicator)
        messageInfoViewSended.translatesAutoresizingMaskIntoConstraints = false
        messageInfoViewRecieved.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = UIFont.systemFont(ofSize: 11)
        playButton.contentVerticalAlignment = .fill
        playButton.contentHorizontalAlignment = .fill
    }
    
    open override func setupConstraints() {
        playButton.constraint(equalTo: CGSize(width: 38, height: 38))
        playButton.addConstraints(left: messageContainerView.leftAnchor, centerY: messageContainerView.centerYAnchor, leftConstant: 5)
        progressView.addConstraints(left: playButton.rightAnchor, right: messageContainerView.rightAnchor, centerY: messageContainerView.centerYAnchor, leftConstant: 7, rightConstant: 30, centerYConstant: -4)
        durationLabel.addConstraints(left: playButton.rightAnchor, centerY: messageContainerView.centerYAnchor, leftConstant: 7, centerYConstant: 8)
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let messageModel = message as? MessageCellViewModelProtocol else { return }
        let viewModel = AudioMessageViewModel(message: messageModel)
        super.configure(with: viewModel, at: indexPath, and: messagesCollectionView)
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError()
        }
        
        let playButtonLeftConstraint = messageContainerView.constraints.filter { $0.identifier == "left" }.first
        let durationLabelRightConstraint = messageContainerView.constraints.filter { $0.identifier == "right" }.first

        if messagesCollectionView.messagesDataSource!.isFromCurrentSender(message: viewModel) {
            playButtonLeftConstraint?.constant = 15
            durationLabelRightConstraint?.constant = -20
            messageInfoViewSended.dateLabel.text = dt.string(from: message.sentDate)
            messageInfoViewSended.dateLabel.textColor = displayDelegate.audioTintColor(for: viewModel, at: indexPath, in: messagesCollectionView)
            messageInfoViewSended.sendStatusImageView.tintColor = displayDelegate.audioTintColor(for: viewModel, at: indexPath, in: messagesCollectionView)
            configureFromCurrentUser(message: message)
            setupContreintsFromCurrentUser()
        } else {
            playButtonLeftConstraint?.constant = 20
            durationLabelRightConstraint?.constant = -20
            messageInfoViewRecieved.dateLabel.text = dt.string(from: message.sentDate)
            messageInfoViewRecieved.dateLabel.textColor = displayDelegate.audioTintColor(for: viewModel, at: indexPath, in: messagesCollectionView)
            configureFromNoCurrentUser()
            setupContreintsFromNoCurrentUser()
        }
    }
}

//MARK: Help
private extension AudioMessageCellCustom {
    
    func configureFromCurrentUser(message: MessageType) {
        messageInfoViewRecieved.isHidden = true
        messageInfoViewSended.isHidden = false
        guard let status = (message as? MessageCellViewModelProtocol)?.status else { return }
        messageInfoViewSended.status = status
    }
    
    func configureFromNoCurrentUser() {
        messageInfoViewSended.isHidden = true
        messageInfoViewRecieved.isHidden = false
    }
    
    func setupContreintsFromCurrentUser() {
        messageInfoViewSended.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -14).isActive = true
        messageInfoViewSended.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -7).isActive = true
        messageInfoViewSended.heightAnchor.constraint(equalToConstant: 8).isActive = true
        messageInfoViewSended.widthAnchor.constraint(equalToConstant: 41).isActive = true
    }
    
    func setupContreintsFromNoCurrentUser() {
        messageInfoViewRecieved.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -14).isActive = true
        messageInfoViewRecieved.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -7).isActive = true
        messageInfoViewRecieved.heightAnchor.constraint(equalToConstant: 8).isActive = true
        messageInfoViewRecieved.widthAnchor.constraint(equalToConstant: 30).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: playButton.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: playButton.centerXAnchor).isActive = true
        activityIndicator.constraint(equalTo: CGSize(width: 38, height: 38))
    }
}
