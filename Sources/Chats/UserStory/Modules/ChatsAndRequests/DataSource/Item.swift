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

enum LastMessageContentType: Hashable {
    case typing
    case text(String)
    case audio
    case image
    case empty
    
    var description: String {
        switch self {
        case .typing:
            return LastMessageConstants.typingPlaceholder
        case .text(let content):
            return content
        case .audio:
            return LastMessageConstants.audioMessagePlaceholer
        case .image:
            return LastMessageConstants.photoMessagePlaceholder
        case .empty:
            return LastMessageConstants.emptyChatPlaceholder
        }
    }
}

enum LastMessageSendingStatus {
    case waiting
    case sended
    case looked
    case another
    
    var image: UIImage? {
        switch self {
        case .waiting:
            return UIImage(named: LastMessageConstants.markWaitinigImageName, in: Bundle.module, with: nil)
        case .sended:
            return UIImage(named: LastMessageConstants.markSendedImageName, in: Bundle.module, with: nil)
        case .looked:
            return UIImage(named: LastMessageConstants.markLookedImageName, in: Bundle.module, with: nil)
        case .another:
            return UIImage()
        }
    }
}

struct Item: Hashable,
             ChatCellViewModelProtocol,
             RequestCellViewModelProtocol {
    var type: ItemType
    var id: String
    var imageURL: String
    var userName: String?
    var lastMessageType: LastMessageContentType?
    var lastMessageSendingStatus: LastMessageSendingStatus?
    var lastMessageDate: String?
    var online: Bool?
    var newMessagesEnable: Bool?
    var newMessagesCount: Int?
    
    init(chat: ChatModelProtocol) {
        self.type = .chats(chat: chat)
        self.id = chat.friendID
        self.userName = chat.friend.userName
        self.imageURL = chat.friend.imageUrl
        self.online = chat.friend.online
        self.newMessagesEnable = !(chat.newMessagesCount == 0)
        self.newMessagesCount = chat.newMessagesCount
        self.lastMessageDate = DateFormatService().convertForActiveChat(from: chat.lastMessage?.date)
        if chat.typing {
            self.lastMessageType = .typing
        } else {
            switch chat.lastMessage?.type {
            case .none:
                self.lastMessageType = .empty
            case .text(let content):
                self.lastMessageType = .text(content)
            case .audio:
                self.lastMessageType = .audio
            case .image:
                self.lastMessageType = .image
            }
        }
        switch chat.lastMessage?.sendingStatus {
        case .none:
            self.lastMessageSendingStatus = .another
        case .looked:
            self.lastMessageSendingStatus = .looked
        case .sended:
            self.lastMessageSendingStatus = .sended
        case .waiting:
            self.lastMessageSendingStatus = .waiting
        }
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
        hasher.combine(lastMessageSendingStatus)
        hasher.combine(lastMessageDate)
        hasher.combine(lastMessageType)
        hasher.combine(online)
        hasher.combine(newMessagesEnable)
        hasher.combine(newMessagesCount)
    }
}

struct LastMessageConstants {
    static let emptyChatPlaceholder = "Напишите сообщение первым(ой)"
    static let audioMessagePlaceholer = "Голосовое сообщение"
    static let photoMessagePlaceholder = "Фотография"
    static let markWaitinigImageName = "wait"
    static let markSendedImageName = "Sented1"
    static let markLookedImageName = "sended3"
    static let typingPlaceholder = "Печатает..."
}
