//
//  File.swift
//  
//
//  Created by Арман Чархчян on 12.05.2022.
//

import Foundation
import Services
import NetworkServices
import ModelInterfaces
import ChatsRouteMap

enum ChatsAndRequestsSocketsKeys: String {
    case fixedFriends
    case fixedRecievedRequest
    case fixedSendedRequests
    case profile
}

protocol ChatsAndRequestsManagerProtocol {
    func getChatsAndRequests() -> (chats: [ChatModelProtocol], requests: [RequestModelProtocol])
    func getChatsAndRequests(completion: @escaping (Result<([ChatModelProtocol], [RequestModelProtocol]), Error>) -> ())
    func observeFriends(completion: @escaping ([ChatModelProtocol], [ChatModelProtocol]) -> Void)
    func observeRequests(completion: @escaping ([RequestModelProtocol], [RequestModelProtocol]) -> Void)
    func addObserveFriendsAndRequestsProfiles(id: String, completion: @escaping (ProfileModelProtocol?) -> ())
    func observeFriendsAndRequestsProfiles(completion: @escaping (ProfileModelProtocol?) -> ())
    func removeObserveFriendsAndRequestsProfiles(id: String)
    func remove(chat: ChatModelProtocol)
}

final class ChatsAndRequestsManager {
    
    private let account: AccountModelProtocol
    private let accountID: String
    private let messagingService: MessagingNetworkServiceProtocol
    private let accountCacheService: AccountCacheServiceProtocol
    private let chatsAndRequestsCacheService: ChatsAndRequestsCacheServiceProtocol
    private let profileService: ProfileInfoNetworkServiceProtocol
    private let requestsService: ChatsAndRequestsNetworkServiceProtocol
    private var sockets = [String: SocketProtocol]()
    
    init(accountID: String,
         account: AccountModelProtocol,
         accountCacheService: AccountCacheServiceProtocol,
         messagingService: MessagingNetworkServiceProtocol,
         chatsAndRequestsCacheService: ChatsAndRequestsCacheServiceProtocol,
         profileService: ProfileInfoNetworkServiceProtocol,
         requestsService: ChatsAndRequestsNetworkServiceProtocol) {
        self.accountID = accountID
        self.account = account
        self.accountCacheService = accountCacheService
        self.chatsAndRequestsCacheService = chatsAndRequestsCacheService
        self.profileService = profileService
        self.requestsService = requestsService
        self.messagingService = messagingService
    }
    
    deinit {
        sockets.values.forEach { $0.remove() }
    }
}

extension ChatsAndRequestsManager: ChatsAndRequestsManagerProtocol {
    
    func getChatsAndRequests() -> (chats: [ChatModelProtocol], requests: [RequestModelProtocol]) {
        return (chatsAndRequestsCacheService.storedChats, chatsAndRequestsCacheService.storedRequests)
    }
    
    func remove(chat: ChatModelProtocol) {
        self.messagingService.removeChat(from: accountID, for: chat.friendID) { }
        self.requestsService.removeFriend(with: chat.friendID, from: self.accountID) { _ in }
    }
    
    func addObserveFriendsAndRequestsProfiles(id: String, completion: @escaping (ProfileModelProtocol?) -> ()) {
        let socket = profileService.initProfileSocket(userID: id) { [weak self] result in
            switch result {
            case .success(let profile):
                let profileModel = ProfileModel(profile: profile)
                self?.chatsAndRequestsCacheService.update(profileModel: profileModel,
                                                          chatID: profile.id)
                completion(profileModel)
            case .failure:
                completion(nil)
            }
        }
        sockets[ChatsAndRequestsSocketsKeys.profile.rawValue + id] = socket
    }
    
    func removeObserveFriendsAndRequestsProfiles(id: String) {
        sockets.removeValue(forKey: ChatsAndRequestsSocketsKeys.profile.rawValue + id)
    }
    
    func observeFriendsAndRequestsProfiles(completion: @escaping (ProfileModelProtocol?) -> ()) {
        account.friendIds.forEach {
            self.addObserveFriendsAndRequestsProfiles(id: $0, completion: completion)
        }
        
        account.waitingsIds.forEach {
            self.addObserveFriendsAndRequestsProfiles(id: $0, completion: completion)
        }
    }
    
    func observeFriends(completion: @escaping ([ChatModelProtocol], [ChatModelProtocol]) -> Void) {
        let socket = requestsService.initFriendsSocket(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success((let add, let removed)):
                self.updateCurrentAccountFriends(add: add, removed: removed)
                var newFriends = [ChatModelProtocol]()
                let group = DispatchGroup()
                add.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let chat = ChatModel(friend: profile)
                            guard !self.chatsAndRequestsCacheService.storedChats.contains(where: { $0.friendID == chat.friendID }) else { return }
                            self.chatsAndRequestsCacheService.store(chatModel: chat)
                            newFriends.insert(chat, at: 0)
                        case .failure:
                            break
                        }
                    }
                }
                var removedFriends = [ChatModelProtocol]()
                removed.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let chat = ChatModel(friend: profile)
                            guard self.chatsAndRequestsCacheService.storedChats.contains(where: { $0.friendID == chat.friendID }) else { return }
                            self.chatsAndRequestsCacheService.removeChat(with: chat.friendID)
                            removedFriends.append(chat)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(newFriends, removedFriends)
                }
            case .failure:
                break
            }
        }
        self.sockets[ChatsAndRequestsSocketsKeys.fixedFriends.rawValue] = socket
    }
    
    func observeRequests(completion: @escaping ([RequestModelProtocol], [RequestModelProtocol]) -> Void) {
        let recievedSocket = requestsService.initRequestsSocket(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success((let add, let removed)):
                self.updateCurrentAccountRequests(add: add, removed: removed)
                var newRequests = [RequestModelProtocol]()
                let group = DispatchGroup()
                add.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let request = RequestModel(sender: profile)
                            guard !self.chatsAndRequestsCacheService.storedRequests.contains(where: { $0.senderID == request.senderID }) else { return }
                            self.chatsAndRequestsCacheService.store(requestModel: request)
                            newRequests.insert(request, at: 0)
                        case .failure:
                            break
                        }
                    }
                }
                var removedRequests = [RequestModelProtocol]()
                removed.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let request = RequestModel(sender: profile)
                            guard self.chatsAndRequestsCacheService.storedRequests.contains(where: { $0.senderID == request.senderID }) else { return }
                            self.chatsAndRequestsCacheService.removeRequest(with: request.senderID)
                            removedRequests.append(request)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    completion(newRequests, removedRequests)
                }
            case .failure:
                break
            }
        }
        let sendedSocket = requestsService.initSendedRequestsSocket(userID: accountID) { [weak self] result in
            switch result {
            case .success((let add, let removed)):
                self?.updateCurrentAccountSendedRequests(add: add, removed: removed)
            case .failure:
                break
            }
        }
        sockets[ChatsAndRequestsSocketsKeys.fixedRecievedRequest.rawValue] = recievedSocket
        sockets[ChatsAndRequestsSocketsKeys.fixedSendedRequests.rawValue] = sendedSocket
    }
    
    func getChatsAndRequests(completion: @escaping (Result<([ChatModelProtocol], [RequestModelProtocol]), Error>) -> ()) {
        var refreshedChats = [ChatModelProtocol]()
        var refreshedRequests = [RequestModelProtocol]()
        let group = DispatchGroup()
        group.enter()
        getRequests { result in
            defer { group.leave() }
            switch result {
            case .success(let requests):
                refreshedRequests = requests
            case .failure:
                break
            }
        }
        group.enter()
        getChats { result in
            defer { group.leave() }
            switch result {
            case .success(let chats):
                refreshedChats = chats
            case .failure:
                break
            }
        }
        group.notify(queue: .main) {
            completion(.success((refreshedChats, refreshedRequests)))
        }
    }
}

private extension ChatsAndRequestsManager {
    
    func updateCurrentAccountFriends(add: [String], removed: [String]) {
        add.forEach {
            self.account.friendIds.insert($0)
        }
        removed.forEach {
            self.account.friendIds.remove($0)
        }
        accountCacheService.store(accountModel: self.account)
    }
    
    func updateCurrentAccountRequests(add: [String], removed: [String]) {
        add.forEach {
            self.account.waitingsIds.insert($0)
        }
        removed.forEach {
            self.account.waitingsIds.remove($0)
        }
        accountCacheService.store(accountModel: self.account)
    }
    
    func updateCurrentAccountSendedRequests(add: [String], removed: [String]) {
        add.forEach {
            self.account.requestIds.insert($0)
        }
        removed.forEach {
            self.account.requestIds.remove($0)
        }
        accountCacheService.store(accountModel: self.account)
    }
    
    func getRequests(completion: @escaping (Result<[RequestModelProtocol], Error>) -> ()) {
        requestsService.waitingIDs(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                self.account.waitingsIds = Set(ids)
                self.accountCacheService.store(accountModel: self.account)
                var requests = [RequestModelProtocol]()
                let group = DispatchGroup()
                ids.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let requestModel = RequestModel(sender: profile)
                            self.chatsAndRequestsCacheService.store(requestModel: requestModel)
                            requests.insert(requestModel, at: 0)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    let stored = self.chatsAndRequestsCacheService.storedRequests
                    func contains(element: RequestModelProtocol, array: [RequestModelProtocol]) -> Bool {
                        for item in array {
                            if element.senderID == item.senderID {
                                return true
                            }
                        }
                        return false
                    }
                    for element in stored {
                        if !contains(element: element, array: requests) {
                            self.chatsAndRequestsCacheService.removeRequest(with: element.senderID)
                        }
                    }
                    completion(.success(requests))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getChats(completion: @escaping (Result<[ChatModelProtocol], Error>) -> ()) {
        requestsService.friendIDs(userID: accountID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ids):
                self.account.friendIds = Set(ids)
                self.accountCacheService.store(accountModel: self.account)
                var chats = [ChatModelProtocol]()
                let group = DispatchGroup()
                ids.forEach {
                    group.enter()
                    self.profileService.getProfileInfo(userID: $0) { result in
                        defer { group.leave() }
                        switch result {
                        case .success(let profile):
                            let chatModel = ChatModel(friend: profile)
                            self.chatsAndRequestsCacheService.store(chatModel: chatModel)
                            chats.insert(chatModel, at: 0)
                        case .failure:
                            break
                        }
                    }
                }
                group.notify(queue: .main) {
                    let stored = self.chatsAndRequestsCacheService.storedChats
                    func contains(element: ChatModelProtocol, array: [ChatModelProtocol]) -> Bool {
                        for item in array {
                            if element.friendID == item.friendID {
                                return true
                            }
                        }
                        return false
                    }
                    for element in stored {
                        if !contains(element: element, array: chats) {
                            self.chatsAndRequestsCacheService.removeChat(with: element.friendID)
                        }
                    }
                    completion(.success(chats))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
