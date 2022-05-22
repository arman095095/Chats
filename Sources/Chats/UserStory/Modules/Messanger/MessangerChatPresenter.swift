//
//  MessangerChatPresenter.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import MessageKit
import ModelInterfaces
import Utils

protocol MessangerChatStringFactoryProtocol {
    var textPlaceholderWriteAllowed: String { get }
    var textPlaceholderWriteNotAllowed: String { get }
}

protocol MessangerChatModuleOutput: AnyObject {
    func reloadChat(_ chat: ChatModelProtocol)
}

protocol MessangerChatModuleInput: AnyObject {
    
}

protocol MessangerChatViewOutput: AnyObject {
    var accountID: String { get }
    var friendUserName: String { get }
    var friendImageURL: URL? { get }
    var displayName: String { get }
    var messagesCount: Int { get }
    var canLoadMore: Bool { get }
    var textPlaceholder: String { get }
    var titleDescription: MessengerTitleView.Descriptions? { get }
    func viewDidLoad()
    func viewWillDisappear()
    func allowLoadMore()
    func loadMoreMessages() -> Bool
    func message(at indexPath: IndexPath) -> MessageType?
    func firstMessageTime(at indexPath: IndexPath) -> String
    func configureAudioCell(cell: AudioMessageCell, message: MessageType)
    func deviceVibrate()
    func sendMessage(text: String)
    func didBeganTyping(text: String)
    func presentProfileAction()
    func beginRecord()
    func cancelRecord()
    func finishRecord()
    func playAudioMessage(message: MessageType, cell: AudioMessageCell)
    func showImageAction(_ image: UIImage)
    func sendPhoto(photo: UIImage, ratio: CGFloat)
}

final class MessangerChatPresenter {
    
    weak var view: MessangerChatViewInput?
    weak var output: MessangerChatModuleOutput?
    private let router: MessangerChatRouterInput
    private let interactor: MessangerChatInteractorInput
    private let stringFactory: MessangerChatStringFactoryProtocol
    private let chat: MessangerChatModelProtocol
    private var timer: Timer?
    private var currentUserTyping: Bool
    private var count: Int
    private var increamentCount: Int
    private(set) var accountID: String
    private(set) var canLoadMore: Bool
    
    init(router: MessangerChatRouterInput,
         interactor: MessangerChatInteractorInput,
         stringFactory: MessangerChatStringFactoryProtocol,
         chat: MessangerChatModelProtocol,
         accountID: String
    ) {
        self.router = router
        self.interactor = interactor
        self.accountID = accountID
        self.chat = chat
        self.stringFactory = stringFactory
        self.canLoadMore = true
        self.currentUserTyping = false
        self.count = 0
        self.increamentCount = Constants.messagesLimit
    }
}

extension MessangerChatPresenter: MessangerChatViewOutput {
    
    func allowLoadMore() {
        canLoadMore = true
    }

    func viewDidLoad() {
        view?.setupInitialState()
        interactor.startObserve()
        loadMoreMessages()
        canLoadMore = true
        interactor.readNewMessages()
        view?.reloadDataAndScroll(animated: false)
    }
    
    func viewWillDisappear() {
        interactor.stopObserving()
        guard let chat = chat as? ChatModelProtocol else { return }
        output?.reloadChat(chat)
    }
    
    var displayName: String {
        ""
    }
    
    var friendUserName: String {
        chat.friend.userName
    }
    
    var friendImageURL: URL? {
        URL(string: chat.friend.imageUrl)
    }
    
    var messagesCount: Int {
        count
    }
    
    var textPlaceholder: String {
        stringFactory.textPlaceholderWriteAllowed
    }
    
    var titleDescription: MessengerTitleView.Descriptions? {
        if chat.typing { return .typing }
        if chat.friend.online { return .online }
        guard let lastActivity = chat.friend.lastActivity else { return nil }
        let description = DateFormatService().getLastActivityDescription(date: lastActivity)
        return .offline(lastActivity: description)
    }
    
    @discardableResult
    func loadMoreMessages() -> Bool {
        canLoadMore = false
        if messagesCount == chat.messages.count {
            return false
        }
        if messagesCount + increamentCount <= chat.messages.count {
            self.count += increamentCount
            return true
        } else {
            self.count = chat.messages.count
            return true
        }
    }
    
    func message(at indexPath: IndexPath) -> MessageType? {
        let index = chat.messages.count - count + indexPath.section
        let message = chat.messages[index]
        return message as? MessageType
    }
    
    func firstMessageTime(at indexPath: IndexPath) -> String {
        let message = chat.messages[indexPath.section]
        return DateFormatService().convertForLabel(from: message.date)
    }
    
    func deviceVibrate() {
        UIDevice().vibrate()
    }
    
    func sendMessage(text: String) {
        interactor.sendTextMessage(content: text)
    }
    
    func sendPhoto(photo: UIImage, ratio: CGFloat) {
        guard let data = photo.jpegData(compressionQuality: 0.4) else { return }
        interactor.sendPhotoMessage(data: data, ratio: Double(ratio))
    }
    
    func didBeganTyping(text: String) {
        if text.isEmpty || text == "" {
            self.interactor.sendDidFinishTyping()
            self.currentUserTyping = false
            return
        }
        if !currentUserTyping {
            interactor.sendDidBeganTyping()
            currentUserTyping = true
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] (timer) in
            guard let self = self else { return }
            self.interactor.sendDidFinishTyping()
            self.currentUserTyping = false
        })
        interactor.sendDidBeganTyping()
    }
    
    func presentProfileAction() {
        router.openProfileModule(profile: chat.friend)
    }
    
    func configureAudioCell(cell: AudioMessageCell, message: MessageType) {
        interactor.configureAudioCell(cell: cell, message: message)
    }
    
    func beginRecord() {
        interactor.beginRecord()
    }
    
    func cancelRecord() {
        interactor.cancelRecord()
    }
    
    func finishRecord() {
        interactor.finishRecord()
    }
    
    func playAudioMessage(message: MessageType, cell: AudioMessageCell) {
        interactor.playAudioMessage(message: message, cell: cell)
    }
    
    func showImageAction(_ image: UIImage) {
        router.openImage(image)
    }
}

extension MessangerChatPresenter: MessangerChatInteractorOutput {
    var chatID: String {
        chat.friendID
    }
    
    func friendIsTyping() {
        chat.typing = true
        view?.updateTopView()
    }
    
    func friendFinishTyping() {
        chat.typing = false
        view?.updateTopView()
    }
    
    func successRecievedNewMessages(_ messages: [MessageModelProtocol]) {
        var newMessages: [MessageModelProtocol] = []
        messages.forEach { message in
            switch message.status {
            case .sended:
                guard let firstIndex = chat.notSendedMessages.firstIndex(where: { $0.id == message.id }) else { return }
                let message = chat.notSendedMessages.remove(at: firstIndex)
                message.status = .sended
            case .incomingNew:
                newMessages.append(message)
            default:
                break
            }
        }
        chat.messages.append(contentsOf: newMessages)
        count += newMessages.count
        canLoadMore = true
        interactor.readNewMessages()
        view?.reloadDataWithNewRecivedMessages(messagesCount: messages.count)
    }
    
    func successLookedMessages() {
        chat.notLookedMessages.forEach { $0.status = .looked }
        chat.notLookedMessages.removeAll()
        view?.reloadData()
    }
    
    func successCreatedMessage(_ message: MessageModelProtocol) {
        self.chat.messages.append(message)
        self.chat.notSendedMessages.append(message)
        self.chat.notLookedMessages.append(message)
        count = chat.messages.count <= increamentCount ? chat.messages.count : increamentCount
        allowLoadMore()
        view?.reloadDataAndScroll(animated: true)
    }
    
    func successAudioRecorded(url: String, duration: Float) {
        interactor.sendAudioMessage(url: url, duration: duration)
    }
}

extension MessangerChatPresenter: MessangerChatModuleInput {
    
}
