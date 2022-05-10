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
import Utils

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
    func select(at indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else { return }
        switch section {
        case .requests:
            let requestItem = requests[indexPath.row]
            guard case .requests(let model) = requestItem.type else { return }
            router.openProfileModule(profile: model.sender)
        case .chats:
            let chatItem = chats[indexPath.row]
            guard case .chats(let model) = chatItem.type else { return }
            // to do
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
            self.view?.reloadData(requests: requests, chats: chats)
            guard case .chats(let model) = chatItem.type else { return }
            interactor.remove(chat: model)
        default:
            break
        }
    }
    
    func filteredChats(text: String) {
    }
    
    var title: String {
        stringFactory.title
    }
    
    func viewDidLoad() {
        view?.setupInitialState()
        interactor.initialLoad()
        interactor.initObserve()
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsInteractorOutput {

    func successLoaded(_ chats: [ChatModelProtocol], _ requests: [RequestModelProtocol]) {
        self.requests = requests.map { Item(request: $0) }
        self.chats = chats.map { Item(chat: $0) }
        view?.reloadData(requests: self.requests, chats: self.chats)
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
        self.chats.append(contentsOf: new)
        self.view?.reloadData(requests: requests, chats: chats)
    }
    
    func changed(newRequests: [RequestModelProtocol], removed: [RequestModelProtocol]) {
        self.requests.removeAll { item in
            removed.contains { $0.senderID == item.id }
        }
        let new = newRequests.map { Item(request: $0) }
        self.requests.append(contentsOf: new)
        self.view?.reloadData(requests: requests, chats: chats)
    }
}

extension ChatsAndRequestsPresenter: ChatsAndRequestsModuleInput {
    
}
