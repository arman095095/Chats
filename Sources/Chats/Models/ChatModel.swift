//
//  File.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation
import ModelInterfaces
import NetworkServices
import Services

public final class ChatModel: ChatModelProtocol,
                              MessangerChatModelProtocol {
    public var friend: ProfileModelProtocol
    public var friendID: String
    public var typing: Bool
    public var notSendedMessages: [MessageModelProtocol]
    public var messages: [MessageModelProtocol]
    public var newMessages: [MessageModelProtocol]
    public var notLookedMessages: [MessageModelProtocol]
    
    public init(friend: ProfileNetworkModelProtocol) {
        self.friend = ProfileModel(profile: friend)
        self.friendID = friend.id
        self.typing = false
        self.messages = []
        self.notSendedMessages = []
        self.newMessages = []
        self.notLookedMessages = []
    }
    
    public init(friend: ProfileModelProtocol) {
        self.friend = friend
        self.friendID = friend.id
        self.typing = false
        self.messages = []
        self.notSendedMessages = []
        self.newMessages = []
        self.notLookedMessages = []
    }
    
    public init?(chat: Chat?) {
        guard let chat = chat,
              let friendID = chat.friendID,
              let friend = chat.friend,
              let profile = ProfileModel(profile: friend) else { return nil }
        self.friendID = friendID
        self.friend = profile
        self.typing = false
        self.notSendedMessages = chat.notSendedMessages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
        self.newMessages = chat.notReadMessages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
        self.notLookedMessages = chat.notLookedMessages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
        self.messages = chat.messages?.compactMap { MessageModel(message: $0 as? Message) } ?? []
        
    }
}

extension ChatModel {
    public var newMessagesCount: Int {
        return newMessages.count
    }
    
    public var lastMessage: MessageModelProtocol? {
        return messages.last
    }
}
