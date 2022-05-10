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
        self.lastMessageContent = "Напишите сообщение"
        self.lastMessageDate = DateFormatService().convertForActiveChat(from: Date())
        self.lastMessageMarkedImage = UIImage(named: "wait", in: Bundle.module, with: nil)
        self.online = chat.friend.online
        self.newMessagesEnable = true
        self.newMessagesCount = 5
    }
    
    init(request: RequestModelProtocol) {
        self.type = .requests(request: request)
        self.id = request.senderID
        self.imageURL = request.sender.imageUrl
    }
}

extension Item {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
