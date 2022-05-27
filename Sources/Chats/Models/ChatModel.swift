//
//  File.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices
import ChatsRouteMap
import Services

final class ChatModel: ChatModelProtocol,
                       MessangerChatModelProtocol {
    var friend: ProfileModelProtocol
    var friendID: String
    var typing: Bool
    var notSendedMessages: [MessageModelProtocol]
    var messages: [MessageModelProtocol]
    var newMessages: [MessageModelProtocol]
    var notLookedMessages: [MessageModelProtocol]
    
    init(friend: ProfileNetworkModelProtocol) {
        self.friend = ProfileModel(profile: friend)
        self.friendID = friend.id
        self.typing = false
        self.messages = []
        self.notSendedMessages = []
        self.newMessages = []
        self.notLookedMessages = []
    }
    
    init(friend: ProfileModelProtocol) {
        self.friend = friend
        self.friendID = friend.id
        self.typing = false
        self.messages = []
        self.notSendedMessages = []
        self.newMessages = []
        self.notLookedMessages = []
    }
    
    init?(chat: Chat?) {
        guard let chat = chat,
              let friendID = chat.friendID,
              let friend = chat.friend,
              let profile = ProfileModel(profile: friend) else { return nil }
        self.friendID = friendID
        self.friend = profile
        self.typing = false
        self.notSendedMessages = chat.notSendedMessages?.lazy.compactMap { MessageModel(message: $0 as? Message) } ?? []
        self.newMessages = chat.notReadMessages?.lazy.compactMap { MessageModel(message: $0 as? Message) } ?? []
        self.notLookedMessages = chat.notLookedMessages?.lazy.compactMap { MessageModel(message: $0 as? Message) } ?? []
        self.messages = chat.messages?.lazy.compactMap { MessageModel(message: $0 as? Message) } ?? []
    }
}

extension ChatModel {
    var newMessagesCount: Int {
        return newMessages.count
    }
    
    var lastMessage: MessageModelProtocol? {
        return messages.last
    }
}
