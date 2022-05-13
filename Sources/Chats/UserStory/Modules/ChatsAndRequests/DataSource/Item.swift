//
//  File.swift
//  
//
//  Created by Арман Чархчян on 10.05.2022.
//

import UIKit
import Utils
import ModelInterfaces

enum ItemType {
    case chats(chat: ChatModelProtocol)
    case requests(request: RequestModelProtocol)
}

struct Item: Hashable,
             ChatCellViewModelProtocol,
             RequestCellViewModelProtocol {
    var type: ItemType
    var id: String
    var imageURL: String
    var userName: String?
    var lastMessageContent: String?
    var lastMessageDate: String?
    var lastMessageMarkedImage: UIImage?
    var online: Bool?
    var newMessagesEnable: Bool?
    var newMessagesCount: Int?
    
    init(chat: ChatModelProtocol) {
        self.type = .chats(chat: chat)
        self.id = chat.friendID
        self.userName = chat.friend.userName
        self.imageURL = chat.friend.imageUrl
        switch chat.messages.last?.type {
        case .none:
            self.lastMessageContent = Constants.emptyChatPlaceholder
        case .text(let content):
            self.lastMessageContent = content
        case.image:
            self.lastMessageContent = Constants.photoMessagePlaceholder
        case .audio:
            self.lastMessageContent = Constants.audioMessagePlaceholer
        }
        self.lastMessageDate = DateFormatService().convertForActiveChat(from: chat.messages.last?.date)
        switch chat.messages.last?.sendingStatus {
        case .sended:
            self.lastMessageMarkedImage = UIImage(named: Constants.markSendedImageName, in: Bundle.module, with: nil)
        case .waiting:
            self.lastMessageMarkedImage = UIImage(named: Constants.markWaitinigImageName, in: Bundle.module, with: nil)
        case .looked:
            self.lastMessageMarkedImage = UIImage(named: Constants.markLookedImageName, in: Bundle.module, with: nil)
        case .none:
            self.lastMessageMarkedImage = nil
        }
        self.online = chat.friend.online
        self.newMessagesEnable = !chat.newMessages.isEmpty
        self.newMessagesCount = chat.newMessages.count
    }
    
    init(request: RequestModelProtocol) {
        self.type = .requests(request: request)
        self.id = request.senderID
        self.imageURL = request.sender.imageUrl
    }
}

extension Item {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(userName)
        hasher.combine(imageURL)
        hasher.combine(lastMessageContent)
        hasher.combine(lastMessageDate)
        hasher.combine(lastMessageMarkedImage)
        hasher.combine(online)
        hasher.combine(newMessagesEnable)
        hasher.combine(newMessagesCount)
    }
}

struct Constants {
    static let emptyChatPlaceholder = "Напишите сообщение первым(ой)"
    static let audioMessagePlaceholer = "Голосовое сообщение"
    static let photoMessagePlaceholder = "Фотография"
    static let markWaitinigImageName = "wait"
    static let markSendedImageName = "Sented1"
    static let markLookedImageName = "sended3"
}
