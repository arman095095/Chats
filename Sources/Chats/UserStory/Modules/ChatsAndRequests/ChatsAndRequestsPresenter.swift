//
//  ChatsAndRequestsPresenter.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import AlertManager
import ModelInterfaces
import ChatsRouteMap
import ProfileRouteMap
import Utils

protocol ChatsAndRequestsStringFactoryProtocol {
    var title: String { get }
}

protocol ChatsAndRequestsModuleOutput: AnyObject {
    
}

protocol ChatsAndRequestsModuleInput: AnyObject {
    
}

protocol ChatsAndRequestsViewOutput: AnyObject {
    var title: String { get }
    func viewDidLoad()
    func stopObserve()
    func select(at indexPath: IndexPath)
    func remove(at indexPath: IndexPath)
    func filteredChats(text: String)
}

final class ChatsAndRequestsPresenter {
    
    weak var view: ChatsAndRequestsViewInput?
    weak var output: ChatsAndRequestsModuleOutput?
    private let stringFactory: ChatsAndRequestsStringFactoryProtocol
    private let alertManager: AlertManagerProtocol
    private let router: ChatsAndRequestsRouterInput
    private let interactor: ChatsAndRequestsInteractorInput
    private var chats: [Item]
    private var requests: [Item]
    
    init(router: ChatsAndRequestsRouterInput,
         interactor: ChatsAndRequestsInteractorInput,
         alertManager: AlertManagerProtocol,
         stringFactory: ChatsAndRequestsStringFactoryProtocol) {
        self.router = router
        self.interactor = interactor
        self.stringFactory = stringFactory
        self.alertManager = alertManager
        self.requests = []
        self.chats = []
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsViewOutput {
    
    func viewDidLoad() {
        view?.setupInitialState()
        loadCache()
        interactor.initSendingManagers()
        interactor.remoteLoad()
    }
    
    func stopObserve() {
        interactor.stopObserving()
    }
    
    var title: String {
        stringFactory.title
    }
    
    func filteredChats(text: String) {
        
    }
    
    func select(at indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else { return }
        switch section {
        case .requests:
            let requestItem = requests[indexPath.row]
            guard let request = interactor.cachedRequest(with: requestItem.id) else { return }
            router.openProfileModule(profile: request.sender, output: self)
        case .chats:
            let chatItem = chats[indexPath.row]
            guard let chat = interactor.cachedChat(with: chatItem.id) else { return }
            router.openMessangerModule(chat: chat, output: self)
        case .chatsEmpty:
            break
        }
    }
    
    func remove(at indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else { return }
        switch section {
        case .requests:
            break
        case .chats:
            let chatItem = chats.remove(at: indexPath.row)
            reloadData()
            guard let chat = interactor.cachedChat(with: chatItem.id) else { return }
            interactor.remove(chat: chat)
        default:
            break
        }
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsInteractorOutput {
    
    func profilesUpdated(with profile: ProfileModelProtocol) {
        if let index = chats.firstIndex(where: { $0.id == profile.id }) {
            chats[index].imageURL = profile.imageUrl
            chats[index].userName = profile.userName
            chats[index].online = profile.online
            view?.reloadData(requests: requests, chats: chats)
        } else if let index = requests.firstIndex(where: { $0.id == profile.id }) {
            requests[index].imageURL = profile.imageUrl
            requests[index].userName = profile.userName
            requests[index].online = profile.online
            view?.reloadData(requests: requests, chats: chats)
        }
    }
    
    func chatProfileUpdated(with profile: ProfileModelProtocol, chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].imageURL = profile.imageUrl
        chats[index].userName = profile.userName
        chats[index].online = profile.online
        view?.reloadData(requests: requests, chats: chats)
    }
    
    func requestProfileUpdated(with profile: ProfileModelProtocol, requestID: String) {
        guard let index = requests.firstIndex(where: { $0.id == requestID }) else { return }
        requests[index].imageURL = profile.imageUrl
        requests[index].userName = profile.userName
        requests[index].online = profile.online
        view?.reloadData(requests: requests, chats: chats)
    }
    
    func newMessagesAtChat(chatID: String, messages: [MessageModelProtocol]) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].updateWith(messages: messages)
        let chat = chats.remove(at: index)
        chats.insert(chat, at: 0)
        reloadData()
    }

    func chatDidBeganTyping(chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].typing = true
        view?.reloadData(requests: requests, chats: chats)
    }
    
    func chatDidFinishTyping(chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].typing = false
        view?.reloadData(requests: requests, chats: chats)
    }
    
    func messagesLookedAtChat(chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }),
              case .sended = chats[index].lastMessageSendingStatus else { return }
        chats[index].lastMessageSendingStatus = .looked
        view?.reloadData(requests: requests, chats: chats)
    }

    func successLoaded(_ chats: [ChatModelProtocol], _ requests: [RequestModelProtocol]) {
        self.requests = requests.map { Item(request: $0) }
        self.chats = chats.map { Item(chat: $0) }.sorted(by: { $0.lastMessageDate! > $1.lastMessageDate! })
        reloadData()
        interactor.startObserve()
        interactor.sendNotSendedMessages()
    }
    
    func failureLoad(message: String) {
        alertManager.present(type: .error, title: message)
    }
    
    func changed(newChats: [ChatModelProtocol], removed: [ChatModelProtocol]) {
        self.chats.removeAll { item in
            removed.contains { chat in
                item.id == chat.friendID
            }
        }
        let new = newChats.map { Item(chat: $0) }
        self.chats.insert(contentsOf: new, at: 0)
        reloadData()
    }
    
    func changed(newRequests: [RequestModelProtocol], removed: [RequestModelProtocol]) {
        self.requests.removeAll { item in
            removed.contains { $0.senderID == item.id }
        }
        let new = newRequests.map { Item(request: $0) }
        self.requests.insert(contentsOf: new, at: 0)
        reloadData()
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsModuleInput { }

extension ChatsAndRequestsPresenter: ProfileModuleOutput {
    func deniedProfile() {
        router.dismissProfileModule()
    }
    
    func acceptedProfile() {
        router.dismissProfileModule()
    }
}

private extension ChatsAndRequestsPresenter {

    func loadCache() {
        self.chats = interactor.cachedChats.map { Item(chat: $0) }.sorted(by: { $0.lastMessageDate! > $1.lastMessageDate! })
        self.requests = interactor.cachedRequests.map { Item(request: $0) }
        reloadData()
    }
    
    func reloadData() {
        view?.reloadData(requests: requests, chats: chats)
        setupBadge()
    }
    
    func setupBadge() {
        let newCount = requests.count + chats.filter { $0.newMessagesCount != 0 }.count
        guard newCount != 0 else {
            router.setupBadge(count: nil)
            return
        }
        router.setupBadge(count: "\(newCount)")
    }
}

extension ChatsAndRequestsPresenter: MessangerChatModuleOutput {
    func reloadChat(_ chat: ChatModelProtocol) {
        guard let index = chats.firstIndex(where: { $0.id == chat.friendID }) else { return }
        chats[index] = Item(chat: chat)
        reloadData()
    }
}
