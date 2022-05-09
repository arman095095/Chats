//
//  ChatsAndRequestsViewController.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import DesignSystem

struct Item: Hashable,
             ChatCellViewModelProtocol,
             RequestCellViewModelProtocol {
    var id: String
    var userName: String
    var imageURL: String
    var lastMessageContent: String
    var lastMessageDate: String
    var lastMessageMarkedImage: UIImage
    var online: Bool
    var newMessagesEnable: Bool
    var newMessagesCount: Int
}

protocol ChatsAndRequestsViewInput: AnyObject {
    func setupInitialState()
    func reloadData(requests: [Item], chats: [Item])
    func reloadDataEdited(items: [Item])
    func reloadDataNewMessageAtChat(chat: Item)
    func reloadDataRemove(request: Item)
    func reloadDataChangeStatusToChat(request: Item)
    func reloadDataNew(request: Item)
    func reloadDataRemoveActiveChat(chat: Item)
}

final class ChatsAndRequestsViewController: UIViewController {
    var output: ChatsAndRequestsViewOutput?
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Sections, Item>!
    private var layout: UICollectionViewCompositionalLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        output?.viewDidLoad()
    }
}

extension ChatsAndRequestsViewController: ChatsAndRequestsViewInput {

    func setupInitialState() {
        setupSearchBar()
        setupLayout()
        setupCollectionView()
        setupDataSource()
    }
    
    func reloadData(requests: [Item], chats: [Item]) {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, Item>()
        snapshot.appendSections([.requests])
        snapshot.appendItems(requests, toSection: .requests)
        snapshot.appendSections([.chats])
        snapshot.appendItems(chats, toSection: .chats)
        snapshot.appendSections([.chatsEmpty])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func reloadDataEdited(items: [Item]) {
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func reloadDataNewMessageAtChat(chat: Item) {
        var snapshot = self.dataSource.snapshot()
        if let destination = snapshot.itemIdentifiers(inSection: .chats).first {
            if destination == chat {
                snapshot.reloadItems([chat])
            } else {
                snapshot.moveItem(chat, beforeItem: destination)
                snapshot.reloadItems([chat])
            }
        } else {
            snapshot.appendItems([chat], toSection: .chats)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func reloadDataRemove(request: Item) {
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteItems([request])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func reloadDataChangeStatusToChat(request: Item) {
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteItems([request])
        let chat = request
        if let destination = snapshot.itemIdentifiers(inSection: .chats).first {
            snapshot.insertItems([chat], beforeItem: destination)
        } else {
            snapshot.appendItems([chat], toSection: .chats)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func reloadDataNew(request: Item) {
        var snapshot = self.dataSource.snapshot()
        if let destination = snapshot.itemIdentifiers(inSection: .requests).first {
            if destination.id == request.id { return }
            snapshot.insertItems([request], beforeItem: destination)
            dataSource.apply(snapshot, animatingDifferences: true)
        } else {
            snapshot.appendItems([request], toSection: .requests)
            dataSource.apply(snapshot, animatingDifferences: false)
        }
    }
    
    func reloadDataRemoveActiveChat(chat: Item) {
        var snapshot = dataSource.snapshot()
        snapshot.deleteItems([chat])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension ChatsAndRequestsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        output?.filteredChats(text: text)
    }
}

private extension ChatsAndRequestsViewController {
    
    func setupSearchBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationItem.title = output?.title
        navigationController?.navigationBar.barTintColor = .systemGray6
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController?.searchBar.placeholder = Constants.searchPlaceholder
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController?.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController?.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController?.searchResultsUpdater = self
        definesPresentationContext = true
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        collectionView.backgroundColor = .systemGray6
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.register(ChatCell.self, forCellWithReuseIdentifier: ChatCell.idCell)
        collectionView.register(RequestCell.self, forCellWithReuseIdentifier: RequestCell.idCell)
        collectionView.register(HeaderItem.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HeaderItem.headerID)
        collectionView.register(EmptyHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EmptyHeaderView.idHeader)
    }
    
    func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Sections, Item>(collectionView: collectionView, cellProvider: { [weak self]
            (collectionView, indexpath, item) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            guard let section = Sections(rawValue: indexpath.section) else { fatalError("section not found") }
            switch section {
            case .chats :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatCell.idCell, for: indexpath) as! ChatCell
                cell.config(viewModel: item)
                cell.output = self
                return cell
            case .requests :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RequestCell.idCell, for: indexpath) as! RequestCell
                cell.config(viewModel: item)
                return cell
            default:
                return nil
            }
        })
        guard let dataSource = dataSource else { return }
        dataSource.supplementaryViewProvider = { collectionView, kind, indexpath -> UICollectionReusableView? in
            guard let section = Sections(rawValue: indexpath.section) else { fatalError("section not found") }
            switch section {
            case .chats :
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderItem.headerID, for: indexpath) as! HeaderItem
                header.config(text: section.title, textColor: .systemGray, fontSize: 22)
                return header
            case .requests :
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderItem.headerID, for: indexpath) as! HeaderItem
                header.config(text: section.title, textColor: .systemGray, fontSize: 22)
                return header
            case .chatsEmpty:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: EmptyHeaderView.idHeader, for: indexpath) as! EmptyHeaderView
                header.config(type: .emptyChats)
                return header
            }
        }
    }
    
    func setupLayout() {
        layout =  UICollectionViewCompositionalLayout { [weak self] (section, _) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            guard let section = Sections(rawValue: section) else { return nil }
            switch section {
            case .chats:
                return self.compositionalVerticalLayoutSection()
            case .requests:
                if self.dataSource.snapshot().itemIdentifiers(inSection: section).isEmpty { return nil }
                return self.compositionalHorizontalLayoutSection()
            case .chatsEmpty:
                if !self.dataSource.snapshot().itemIdentifiers(inSection: .chats).isEmpty { return nil }
                return self.compositionalVerticalLayoutSection()
            }
        }
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = Constants.sectionsSpacing
        layout.configuration = config
    }
    
    //MARK: Vertical Section Layout
    func compositionalVerticalLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Constants.chatCellHeight))
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(1))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.layout1,
                                                        leading: Constants.layout2,
                                                        bottom: Constants.layout1,
                                                        trailing: Constants.layout2)
        section.interGroupSpacing = Constants.verticalGroupSpacing
        
        return section
    }
    
    //MARK: Horizontal Section Layout
    func compositionalHorizontalLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(Constants.requestCellHeight), heightDimension: .absolute(Constants.requestCellHeight))
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(1))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        section.boundarySupplementaryItems = [header]
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Constants.horizontalGroupSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: Constants.layout1,
                                                        leading: Constants.layout2,
                                                        bottom: Constants.zero,
                                                        trailing: Constants.zero)
        
        return section
    }
}

extension ChatsAndRequestsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else { return }
        switch section {
        case .chats:
            let cell = collectionView.cellForItem(at: indexPath) as! ChatCell
            cell.animateSelect()
            output?.selectChat(at: indexPath)
        case .requests:
            output?.selectRequest(at: indexPath)
        default:
            break
        }
    }
}

extension ChatsAndRequestsViewController: ChatCellOuput {
    func removeChat(at cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        output?.removeChat(at: indexPath)
    }
}

private extension ChatsAndRequestsViewController {

    struct Constants {
        static let layout1: CGFloat = 15
        static let layout2: CGFloat = 16
        static let zero: CGFloat = 0
        static let verticalGroupSpacing: CGFloat = 2
        static let horizontalGroupSpacing: CGFloat = 15
        static let sectionsSpacing: CGFloat = 15
        static let searchPlaceholder = "Поиск"
        static let chatCellHeight: CGFloat = 75
        static let requestCellHeight: CGFloat = 65
    }

    enum Sections: Int, CaseIterable {
        case requests
        case chats
        case chatsEmpty
        
        var title: String {
            switch self {
            case .chats:
                return "Чаты"
            case .requests:
                return "Запросы"
            case .chatsEmpty:
                return ""
            }
        }
    }
}

/*
 class ChatsViewController: UIViewController {
     
     private var collectionView: UICollectionView!
     private var dataSource: UICollectionViewDiffableDataSource<Sections, MChat>!
     private var layout: UICollectionViewCompositionalLayout!
     private var chatsViewModel: ChatsViewModel
     private let dispose = DisposeBag()
     
     override func viewDidLoad() {
         super.viewDidLoad()
         setupSearchBar()
         setupLayout()
         setupCollectionView()
         setupDataSource()
         DispatchQueue.main.async {
             self.reloadData()
             self.setupBinding()
         }
     }
     
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         tabBarController?.tabBar.isHidden = false
     }
 }

 //MARK: Setup UI
 private extension ChatsViewController {
     
 }

 //MARK: Setup Binding
 private extension ChatsViewController {
     
     func setupBinding() {
         
         chatsViewModel.chatChangedFromWaitingToActive.asDriver().drive(onNext: { [weak self] chat in
             if let chat = chat {
                 self?.reloadDataChangeChatStatus(chat: chat)
             }
             }).disposed(by: dispose)
         
         chatsViewModel.newMessageInActiveChat.asDriver().drive(onNext: { [weak self] chat in
             if let chat = chat {
                 self?.reloadDataNewMessageActiveChat(chat: chat)
             }
         }).disposed(by: dispose)
         
         chatsViewModel.info.asDriver().drive(onNext: { inf in
             if let inf = inf {
                 Alert.present(type: .success, title: "\(inf.0) \(inf.1)")
             }
         }).disposed(by: dispose)
         
         chatsViewModel.newWaitingChatRequest.asDriver().drive(onNext: { [weak self] chat in
             guard let self = self else { return }
             if let chat = chat {
                 self.reloadDataNewWaitingChat(chat: chat)
                 let answerVC = Builder.shared.answerVC(chat: chat, delegate: self)
                 self.present(answerVC, animated: true, completion: nil)
             }
         }).disposed(by: dispose)
         
         chatsViewModel.chatsChangedUpdate.asDriver().drive(onNext: { [weak self] chats in
             if chats.isEmpty { return }
             self?.reloadDataEditedChats(chats: chats)
         }).disposed(by: dispose)
         
         chatsViewModel.sendingError.asDriver().drive(onNext: { error in
             if let error = error {
                 if let _ = error as? ConnectionError {
                     Alert.present(type: .connection)
                 } else {
                     Alert.present(type: .error,title: error.localizedDescription)
                 }
             }
         }).disposed(by: dispose)
     }
 }

 //MARK: ChatsOperationsDelegate
 extension ChatsViewController: ChatsOperationsDelegate {
     
     func removeActiveChat(chat: MChat) {
         reloadDataRemoveActiveChat(chat: chat)
         chatsViewModel.removeActiveChat(chat: chat)
     }
     
     func removeWaitingChat(chat: MChat) {
         reloadDataRemoveWaitingChat(chat: chat)
         chatsViewModel.removeWaitingChat(chat: chat)
     }
     
     func changeChatStatus(chat: MChat) {
         reloadDataChangeChatStatus(chat: chat)
         chatsViewModel.changeChatStatus(chat: chat)
     }
 }

 //MARK: Setup SearchController
 extension ChatsViewController: UISearchResultsUpdating {
     
     func updateSearchResults(for searchController: UISearchController) {
         guard let text = searchController.searchBar.text else { return }
         reloadData(with: text)
     }
 }

 //MARK: CollectionViewDelegate
 extension ChatsViewController: UICollectionViewDelegate {
     
     func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         guard let chat = self.dataSource.itemIdentifier(for: indexPath) else { return }
         guard let section = Sections(rawValue: indexPath.section) else { return }
         switch section {
         case .activeChats:
             let cell = collectionView.cellForItem(at: indexPath) as! ActiveChatCell
             cell.animateSelect()
             let messangerVC = Builder.shared.messengerVC(delegate: self, chat: chat, managers: chatsViewModel.managers)
             navigationController?.pushViewController(messangerVC, animated: true)
         case .waitingChats:
             let answerVC = Builder.shared.answerVC(chat: chat, delegate: self)
             self.present(answerVC, animated: true, completion: nil)
         default:
             break
         }
     }
 }

 //MARK: Setup CollectionView Layout
 private extension ChatsViewController {
     
     
 }

 //MARK: Cell reload while Dismiss MessangerViewController
 extension ChatsViewController: CellReloaderProtocol {
     func reloadCell(with chat: MChat) {
         reloadDataEditedChats(chats: [chat])
     }
 }
*/
