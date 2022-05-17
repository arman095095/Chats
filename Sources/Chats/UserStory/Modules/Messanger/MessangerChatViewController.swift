//
//  MessangerChatViewController.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import DesignSystem
import AlertManager
import MessageKit
import InputBarAccessoryView
import Services
import ModelInterfaces

protocol MessangerChatViewInput: AnyObject {
    func setupInitialState()
    func updateWithNewSendedMessage()
    func updateWithSuccessSendedMessage()
    func updateWithNewRecivedMessages(messagesCount: Int)
    func updateWithSuccessLookedMessages()
    func updateTopView()
}

final class MessangerChatViewController: MessagesViewController {
    var output: MessangerChatViewOutput
    private let titleView = MessengerTitleView()
    private let timerView = TimerView()
    
    init(output: MessangerChatViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        output.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard self.isMovingFromParent else { return }
        output.viewWillDisappear()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if messagesCollectionView.indexPathsForVisibleItems.contains(IndexPath(item: 0, section: Int(3))) && output.canLoadMore {
            if output.loadMoreMessages() {
                self.messagesCollectionView.reloadDataAndKeepOffset()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.output.canLoadMore = true
                })
            }
        }
    }
}

extension MessangerChatViewController: MessangerChatViewInput {
    func setupInitialState() {
        setupViews()
        setupInputBar()
        addGesture()
        setupTopBar()
        messagesCollectionView.scrollToLastItem(animated: false)
    }
    
    func updateWithSuccessSendedMessage() {
        messagesCollectionView.reloadData()
    }
    
    func updateWithNewSendedMessage() {
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
    }
    
    func updateWithNewRecivedMessages(messagesCount: Int) {
        if messagesCollectionView.indexPathsForVisibleItems.contains(IndexPath(item: 0, section: messagesCollectionView.numberOfSections - 1)) && messagesCount < 3 {
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToLastItem(animated: true)
        } else {
            self.messagesCollectionView.reloadData()
        }
    }
    
    func updateWithSuccessLookedMessages() {
        self.messagesCollectionView.reloadData()
    }
    
    func updateTopView() {
        titleView.set(title: output.friendUserName, imageURL: output.friendImageURL, description: output.titleDescription)
    }
}

extension MessangerChatViewController {
    
    @objc private func sendPhotoTapped() {
        self.presentImagePicker()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let photo = (info[.originalImage] as! UIImage)
        output.sendPhoto(photo: photo, ratio: photo.size.width/photo.size.height)
        picker.dismiss(animated: true, completion: nil)
    }
}

//MARK: MessagesDataSource
extension MessangerChatViewController: MessagesDataSource {
    
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return output.messagesCount
    }
    
    func currentSender() -> SenderType {
        return MessageModel.Sender(senderId: output.accountID, displayName: output.displayName)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        guard let message = output.message(at: indexPath) else { fatalError() }
        return message
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let viewModel = message as? MessageCellViewModelProtocol else { return nil }
        if viewModel.firstOfDate {
            return NSAttributedString(string: output.firstMessageTime(at: indexPath), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        else { return nil }
    }
}

//MARK: MessagesLayoutDelegate
extension MessangerChatViewController: MessagesLayoutDelegate {
    
    func footerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        guard let message = message as? MessageCellViewModelProtocol else { return Constants.zero }
        if message.firstOfDate { return Constants.topLabelHeight }
        else { return Constants.zero }
    }
}

//MARK: MessagesDisplayDelegate
extension MessangerChatViewController: MessagesDisplayDelegate {
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : UIColor.mainApp()
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .black : .white
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if isFromCurrentSender(message: message) {
            return .bubbleTailOutline(.systemGray4, .bottomRight, .pointedEdge)
        } else {
            return .bubbleTailOutline(.systemGray4, .bottomLeft, .curved)
        }
    }
    
    func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.mainApp() : .white
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        if !isFromCurrentSender(message: message) {
            cell.progressView.trackTintColor = .white
            cell.progressView.progressTintColor = .systemGray
        } else {
            cell.progressView.trackTintColor = UIProgressView().trackTintColor
            cell.progressView.progressTintColor = UIColor.mainApp()
        }
        
        output.configureAudioCell(cell: cell, message: message)
    }
}

//MARK: InputBarAccessoryViewDelegate (Send Button)
extension MessangerChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if text == "" || text.isEmpty {
            output.deviceVibrate()
            return
        }
        output.sendMessage(text: text)
        inputBar.inputTextView.text = ""
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        output.didBeganTyping(text: text)
        inputBar.sendButton.isEnabled = true
        let empty = text == "" || text.isEmpty
        let image = UIImage(named: empty ? Constants.recordBeginImageName : Constants.sendButtonImageName, in: Bundle.module, with: nil)
        inputBar.sendButton.setImage(image, for: .normal)
        inputBar.sendButton.setupForSystemImageColor(color: UIColor.mainApp())
    }
}

//MARK: Setup UI
private extension MessangerChatViewController {
    
    func addGesture() {
        let press = UILongPressGestureRecognizer(target: self, action: #selector(recordAudio(gesture:)))
        press.minimumPressDuration = 0.3
        messageInputBar.sendButton.addGestureRecognizer(press)
    }
    
    func setupViews() {
        messagesCollectionView.backgroundColor = UIColor.mainWhite()
        messageInputBar = InputBarAccessoryView()
        messageInputBar.delegate = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.keyboardDismissMode = .none
        messagesCollectionView.register(TextMessageCellCustom.self)
        messagesCollectionView.register(PhotoMessageCellCustom.self)
        messagesCollectionView.register(AudioMessageCellCustom.self)
        maintainPositionOnKeyboardFrameChanged = true
    }
    
    func setupTopBar() {
        navigationItem.largeTitleDisplayMode = .never
        titleView.delegate = self
        navigationItem.titleView = titleView
        titleView.set(title: output.friendUserName, imageURL: output.friendImageURL, description: output.titleDescription)
    }
    
    func setupInputBar() {
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.backgroundView.backgroundColor = UIColor.mainWhite()
        
        messageInputBar.inputTextView.backgroundColor = .white
        messageInputBar.inputTextView.placeholderTextColor = .gray
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 14, left: 15, bottom: 14, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor.gray.cgColor
        messageInputBar.inputTextView.layer.borderWidth = 0.2
        messageInputBar.inputTextView.layer.cornerRadius = 18.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        
        messageInputBar.inputTextView.placeholder = output.textPlaceholder
        
        setupSendButton()
        setupSendPhotoButton()
        setupTimerRecord()
        reloadInputViews()
    }
    
    func setupTimerRecord() {
        messageInputBar.addSubview(timerView)
        timerView.frame = CGRect(x: 20, y: 20, width: 200, height: 10)
        timerView.alpha = 0
    }
    
    func setupSendButton() {
        messageInputBar.sendButton.setImage(UIImage(named: Constants.recordBeginImageName, in: Bundle.module, with: nil), for: .normal)
        messageInputBar.setRightStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.sendButton.contentEdgeInsets = .zero
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.setupForSystemImageColor(color: UIColor.mainApp())
        messageInputBar.rightStackView.alignment = .center
        messageInputBar.sendButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.middleContentViewPadding.right = 10
        messageInputBar.sendButton.isEnabled = true
    }
    
    func setupSendPhotoButton() {
        let photoButton = InputBarButtonItem(type:.system)
        photoButton.addTarget(self, action: #selector(sendPhotoTapped), for: .touchUpInside)
        photoButton.image = UIImage(named: Constants.sendPhotoButtonImageName, in: Bundle.module, with: nil)
        photoButton.setupForSystemImageColor(color: UIColor.mainApp())
        photoButton.setSize(CGSize(width: 36, height: 36), animated: false)
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([photoButton], forStack: .left, animated: false)
        messageInputBar.middleContentViewPadding.left = 10
    }
}

//MARK: MessengerTitleViewDelegate
extension MessangerChatViewController: MessengerTitleViewDelegate {
    
    func presentProfile() {
        output.presentProfileAction()
    }
}

//MARK: AudioRecordUI
private extension MessangerChatViewController {
    
    @objc func recordAudio(gesture: UILongPressGestureRecognizer) {
        if let text = messageInputBar.inputTextView.text, text != "", !text.isEmpty { return }
        switch gesture.state {
        case .began:
            recordAudio()
        case .changed:
            leadingPan(gesture: gesture)
        case .ended:
            finishRecord(gesture: gesture)
        default:
            break
        }
    }
    
    func leadingPan(gesture: UILongPressGestureRecognizer) {
        let x = gesture.location(in: self.messageInputBar.rightStackView).x - self.messageInputBar.rightStackView.frame.width/2
        if x < -4 {
            messageInputBar.sendButton.transform = CGAffineTransform.init(translationX: x, y: 0)
            timerView.setAlpha(alpha: -x/(messageInputBar.frame.width/2))
        }
        if -x > (messageInputBar.frame.width/2 - messageInputBar.rightStackView.frame.width) {
            messageInputBar.sendButton.tintColor = .red
        } else {
            messageInputBar.sendButton.tintColor = UIColor.mainApp()
        }
    }
    
    func recordAudio() {
        messageInputBar.sendButton.setImage(UIImage(named: Constants.recordBeginImageName, in: Bundle.module, with: nil), for: .normal)
        output.deviceVibrate()
        UIView.animate(withDuration: 0.5) { self.timerView.alpha = 1 }
        messageInputBar.inputTextView.isHidden = true
        messageInputBar.leftStackView.isHidden = true
        timerView.begin()
        messageInputBar.sendButton.pulse()
        output.beginRecord()
    }
    
    func finishRecord(gesture: UILongPressGestureRecognizer) {
        messageInputBar.sendButton.setImage(UIImage(named: Constants.recordFinishImageName, in: Bundle.module, with: nil), for: .normal)
        messageInputBar.sendButton.tintColor = UIColor.mainApp()
        messageInputBar.sendButton.transform = .identity
        timerView.alpha = 0
        timerView.stop()
        messageInputBar.sendButton.stopPulse()
        messageInputBar.leftStackView.isHidden = false
        messageInputBar.inputTextView.isHidden = false
        output.deviceVibrate()
        let x = gesture.location(in: self.messageInputBar.rightStackView).x - self.messageInputBar.rightStackView.frame.width/2
        if -x > (messageInputBar.frame.width/2 - messageInputBar.rightStackView.frame.width) {
            output.cancelRecord()
        } else {
            output.finishRecord()
        }
    }
}

//MARK: MessageCellDelegate AudioPlay
extension MessangerChatViewController: MessageCellDelegate {
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else { return }
        output.playAudioMessage(message: message, cell: cell)
    }
}

//MARK: MessageCellDelegate Other Tap
extension MessangerChatViewController {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        guard let image = (messagesCollectionView.cellForItem(at: indexPath) as? PhotoMessageCellCustom)?.imageView.image else { return }
        output.showImageAction(image)
    }
    
    func didTapBackground(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        messageInputBar.inputTextView.resignFirstResponder()
    }
}

//MARK: Custom Cells setup
extension MessangerChatViewController {
    
    func customCellSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator {
        
        switch message.kind {
        case .custom(let kind):
            switch kind as! MessageKind {
            case .text(_):
                let textSizeCalculator = TextMessageSizeCalculatorCustom(layout: messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout)
                textSizeCalculator.setup()
                return textSizeCalculator
            case .photo(_):
                let photoSizeCalculator = PhotoMessageSizeCalculatorCustom(layout: messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout)
                photoSizeCalculator.setup()
                return photoSizeCalculator
            case .audio(_):
                let audioSizeCalculator = AudioMessageSizeCalculatorCustom(layout: messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout)
                audioSizeCalculator.setup()
                return audioSizeCalculator
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
    
    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        switch message.kind {
        case .custom(let kind):
            switch kind as! MessageKind {
            case .text:
                let cell = messagesCollectionView.dequeueReusableCell(TextMessageCellCustom.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            case .photo:
                let cell = messagesCollectionView.dequeueReusableCell(PhotoMessageCellCustom.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            case .audio:
                let cell = messagesCollectionView.dequeueReusableCell(AudioMessageCellCustom.self, for: indexPath)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            default:
                fatalError()
            }
        default:
            fatalError()
        }
    }
}
