//
//  PhotoMessageCellCustom.swift
//  diffibleData
//
//  Created by Arman Davidoff on 11.12.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import MessageKit
import Foundation
import DesignSystem
import UIKit

class PhotoMessageCellCustom: MessageContentCell {
    
    /// The image view display the media content.
    open var imageView: ImageView = {
        let imageView = ImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    private lazy var activityIndicator : CustomActivityIndicator = {
        let view = CustomActivityIndicator()
        view.lineWidth = 3
        view.strokeColor = UIColor.mainApp()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var dt: DateFormatter = {
        let dt = DateFormatter()
        dt.locale = Locale(identifier: "ru_RU")
        dt.dateFormat = "HH:mm"
        return dt
    }()
    
    private var messageInfoViewSended = MessageInfoView(type: .sender(.photo))
    private var messageInfoViewRecieved = MessageInfoView(type: .recieved(.photo))

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.fillSuperview()
        activityIndicator.inCenterSuperView()
        activityIndicator.constraint(equalTo: CGSize(width: 35, height: 35))
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(activityIndicator)
        messageContainerView.addSubview(messageInfoViewSended)
        messageContainerView.addSubview(messageInfoViewRecieved)
        messageInfoViewSended.translatesAutoresizingMaskIntoConstraints = false
        messageInfoViewRecieved.translatesAutoresizingMaskIntoConstraints = false
        setupConstraints()
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        messageInfoViewSended.removeAnimationFromSendStatusImage()
        messageInfoViewRecieved.removeAnimationFromSendStatusImage()
        messageInfoViewSended.sendStatusImageView.image = nil
        messageInfoViewRecieved.sendStatusImageView.image = nil
        activityIndicator.completeLoading(success: true)
        activityIndicator.isHidden = true
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let messageModel = message as? MessageCellViewModelProtocol else { return }
        let viewModel = PhotoMessageViewModel(message: messageModel)
        super.configure(with: viewModel, at: indexPath, and: messagesCollectionView)
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate,
              let dataSource = messagesCollectionView.messagesDataSource else {
            return
        }
        if dataSource.isFromCurrentSender(message: viewModel) {
            messageInfoViewSended.dateLabel.text = dt.string(from: message.sentDate)
            configureFromCurrentUser(message: message, viewModel: viewModel)
            setupContreintsFromCurrentUser()
        } else {
            messageInfoViewRecieved.dateLabel.text = dt.string(from: message.sentDate)
            configureFromNoCurrentUser(message: message, viewModel: viewModel, delegate: displayDelegate, indexPath: indexPath, messagesCollectionView: messagesCollectionView)
            setupConstreintsFromNoCurrentUser()
        }
    }
    
    /// Handle tap gesture on contentView and its subviews.
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: imageView)

        guard imageView.frame.contains(touchLocation) else {
            super.handleTapGesture(gesture)
            return
        }
        delegate?.didTapImage(in: self)
    }
    
}

//MARK: Help
private extension PhotoMessageCellCustom {
    
    private func configureFromCurrentUser(message: MessageType, viewModel: PhotoMessageViewModel) {
        messageInfoViewRecieved.isHidden = true
        messageInfoViewSended.isHidden = false
        guard let status = (message as? MessageCellViewModelProtocol)?.sendingStatus else { return }
        messageInfoViewSended.status = status
        switch status {
        case .waiting:
            activityIndicator.isHidden = false
            activityIndicator.startLoading()
        case .sended:
            activityIndicator.completeLoading(success: true)
            activityIndicator.isHidden = true
        default:
            break
        }
        switch viewModel.kind {
        case .photo(let item):
            guard let urlString = item.url?.absoluteString else { return }
            let url = FileManager.getDocumentsDirectory().appendingPathComponent(urlString)
            do {
                try imageView.set(localURL: url)
            } catch {
                imageView.set(imageURL: item.url)
            }
        default:
            break
        }
    }
    
    func configureFromNoCurrentUser(message: MessageType, viewModel: PhotoMessageViewModel, delegate: MessagesDisplayDelegate,indexPath: IndexPath, messagesCollectionView: MessagesCollectionView) {
        messageInfoViewSended.isHidden = true
        messageInfoViewRecieved.isHidden = false
        switch viewModel.kind {
        case .photo(let item):
            if let image = item.image { imageView.image = image }
            else if let url = item.url {
                imageView.contentMode = .scaleAspectFill
                activityIndicator.isHidden = false
                activityIndicator.startLoading()
                imageView.set(imageURL: url, placeholder: item.placeholderImage) { [weak self] image in
                    guard let self = self, let _ = image  else { return }
                    self.imageView.contentMode = .scaleToFill
                    self.activityIndicator.completeLoading(success: true)
                    self.activityIndicator.isHidden = true
                    delegate.configureMediaMessageImageView(self.imageView, for: viewModel, at: indexPath, in: messagesCollectionView)
                }
            }
        default:
            break
        }
    }
    
    func setupConstreintsFromNoCurrentUser() {
        messageInfoViewRecieved.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -8).isActive = true
        messageInfoViewRecieved.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -7).isActive = true
        messageInfoViewRecieved.widthAnchor.constraint(equalToConstant: 38).isActive = true
        messageInfoViewRecieved.heightAnchor.constraint(equalToConstant: 14).isActive = true
    }
    
    func setupContreintsFromCurrentUser() {
        messageInfoViewSended.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -8).isActive = true
        messageInfoViewSended.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -7).isActive = true
        messageInfoViewSended.widthAnchor.constraint(equalToConstant: 53).isActive = true
        messageInfoViewSended.heightAnchor.constraint(equalToConstant: 14).isActive = true
    }
}
