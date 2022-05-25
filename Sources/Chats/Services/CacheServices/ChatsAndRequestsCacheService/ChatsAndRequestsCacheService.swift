//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import Foundation
import ModelInterfaces
import ChatsRouteMap
import Services

typealias ChatsAndRequestsCacheServiceProtocol = ChatsCacheServiceProtocol & RequestsCacheServiceProtocol

protocol ChatsCacheServiceProtocol {
    var storedChats: [ChatModelProtocol] { get }
    func store(chatModel: ChatModelProtocol)
    func removeChat(with id: String)
    func chat(with id: String) -> ChatModelProtocol?
    func update(profileModel: ProfileModelProtocol, chatID: String)
}

protocol RequestsCacheServiceProtocol {
    var storedRequests: [RequestModelProtocol] { get }
    func store(requestModel: RequestModelProtocol)
    @discardableResult
    func removeRequest(with id: String) -> RequestModelProtocol?
    func request(with id: String) -> RequestModelProtocol?
    func update(profileModel: ProfileModelProtocol, requestID: String)
}

final class ChatsAndRequestsCacheService {
    private let coreDataService: CoreDataServiceProtocol
    private let account: Account?
    
    init(accountID: String, coreDataService: CoreDataServiceProtocol) {
        self.coreDataService = coreDataService
        self.account = coreDataService.model(Account.self, id: accountID)
    }
}

extension ChatsAndRequestsCacheService: ChatsCacheServiceProtocol {
    var storedChats: [ChatModelProtocol] {
        guard let storedAccount = account,
              let storedChats = storedAccount.chats else { return [] }
        return storedChats.compactMap { ChatModel(chat: $0 as? Chat) }
    }
    
    func store(chatModel: ChatModelProtocol) {
        guard let storedAccount = account,
              let storedChats = storedAccount.chats else { return }
        guard let chat = storedChats.first (where: { ($0 as? Chat)?.friendID == chatModel.friendID }) as? Chat else {
            create(chatModel: chatModel)
            return
        }
        update(chat: chat, model: chatModel)
    }
    
    func chat(with id: String) -> ChatModelProtocol? {
        guard let chat = chatObject(with: id) else { return nil }
        return ChatModel(chat: chat)
    }
    
    func update(profileModel: ProfileModelProtocol, chatID: String) {
        guard let account = account else { return }
        guard let chat = account.chats?.first(where: { ($0 as? Chat)?.friendID == chatID }) as? Chat,
              let friend = chat.friend else { return }
        coreDataService.update(friend) { profile in
            fillFields(profile: profile, model: profileModel)
        }
    }
    
    func removeChat(with id: String) {
        guard let account = account else { return }
        guard let chat = account.chats?.first(where: { ($0 as? Chat)?.friendID == id }) as? Chat else { return }
        account.removeFromChats(chat)
        coreDataService.saveContext()
        coreDataService.remove(chat)
    }
}

extension ChatsAndRequestsCacheService: RequestsCacheServiceProtocol {
    var storedRequests: [RequestModelProtocol] {
        guard let storedAccount = account,
              let storedRequests = storedAccount.requests else { return [] }
        return storedRequests.compactMap { RequestModel(request: $0 as? Request) }
    }
    
    func store(requestModel: RequestModelProtocol) {
        guard let storedAccount = account,
              let storedRequests = storedAccount.requests else { return }
        guard let request = storedRequests.first (where: { ($0 as? Request)?.senderID == requestModel.senderID }) as? Request else {
            create(requestModel: requestModel)
            return
        }
        update(request: request, model: requestModel)
    }
    
    @discardableResult
    func removeRequest(with id: String) -> RequestModelProtocol? {
        guard let account = account else { return nil }
        guard let request = account.requests?.first(where: { ($0 as? Request)?.senderID == id }) as? Request else { return nil }
        let requestModel = RequestModel(request: request)
        account.removeFromRequests(request)
        coreDataService.saveContext()
        coreDataService.remove(request)
        return requestModel
    }
    
    func request(with id: String) -> RequestModelProtocol? {
        guard let account = account else { return nil }
        guard let request = account.requests?.first(where: { ($0 as? Request)?.senderID == id }) as? Request else { return nil }
        return RequestModel(request: request)
    }
    
    func update(profileModel: ProfileModelProtocol, requestID: String) {
        guard let account = account else { return }
        guard let request = account.requests?.first(where: { ($0 as? Request)?.senderID == requestID }) as? Request,
              let sender = request.sender else { return }
        coreDataService.update(sender) { profile in
            fillFields(profile: profile, model: profileModel)
        }
    }
}

private extension ChatsAndRequestsCacheService {
    
    func chatObject(with chatID: String) -> Chat? {
        guard let account = account else { return nil }
        guard let chat = account.chats?.first(where: { ($0 as? Chat)?.friendID == chatID }) as? Chat else { return nil }
        return chat
    }
    
    func create(chatModel: ChatModelProtocol) {
        guard let storedAccount = account else { return }
        let chat = coreDataService.initModel(Chat.self) { chat in
            chat.friendID = chatModel.friendID
            chat.friend = coreDataService.initModel(Profile.self) { profile in
                fillFields(profile: profile, model: chatModel.friend)
            }
        }
        storedAccount.addToChats(chat)
        coreDataService.saveContext()
    }
    
    func update(chat: Chat, model: ChatModelProtocol) {
        guard let friend = chat.friend else {
            coreDataService.initModel(Profile.self) { profile in
                fillFields(profile: profile, model: model.friend)
            }
            return
        }
        coreDataService.update(chat) { chat in
            fillFields(profile: friend, model: model.friend)
        }
    }
}

private extension ChatsAndRequestsCacheService {
    func create(requestModel: RequestModelProtocol) {
        guard let storedAccount = account else { return }
        let request = coreDataService.initModel(Request.self) { request in
            request.senderID = requestModel.senderID
            request.sender = coreDataService.initModel(Profile.self) { profile in
                fillFields(profile: profile, model: requestModel.sender)
            }
        }
        storedAccount.addToRequests(request)
        coreDataService.saveContext()
    }
    
    func update(request: Request, model: RequestModelProtocol) {
        guard let sender = request.sender else {
            coreDataService.initModel(Profile.self) { profile in
                fillFields(profile: profile, model: model.sender)
            }
            return
        }
        coreDataService.update(request) { request in
            fillFields(profile: sender, model: model.sender)
        }
    }
}

private extension ChatsAndRequestsCacheService {
    func fillFields(profile: Profile,
                    model: ProfileModelProtocol) {
        profile.userName = model.userName
        profile.info = model.info
        profile.sex = model.sex
        profile.imageUrl = model.imageUrl
        profile.id = model.id
        profile.country = model.country
        profile.city = model.city
        profile.birthday = model.birthday
        profile.removed = model.removed
        profile.online = model.online
        profile.lastActivity = model.lastActivity
        profile.postsCount = Int16(model.postsCount)
    }
}
