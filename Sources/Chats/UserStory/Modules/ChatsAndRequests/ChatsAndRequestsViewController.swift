//
//  ChatsAndRequestsViewController.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit
import DesignSystem

protocol ChatsAndRequestsViewInput: AnyObject {
    func setupInitialState()
    func reloadData(requests: [Item], chats: [Item])
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
    
    deinit {
        output?.stopObserve()
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
}

extension ChatsAndRequestsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        output?.filteredChats(text: text)
    }
}

private extension ChatsAndRequestsViewController {
    
    func setupSearchBar() {
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
                header.config(text: section.title, textColor: Constants.headerTextColor, fontSize: Constants.headerFontSize)
                return header
            case .requests :
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HeaderItem.headerID, for: indexpath) as! HeaderItem
                header.config(text: section.title, textColor: Constants.headerTextColor, fontSize: Constants.headerFontSize)
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
        default:
            break
        }
        output?.select(at: indexPath)
    }
}

extension ChatsAndRequestsViewController: ChatCellOuput {
    func removeChat(at cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        output?.remove(at: indexPath)
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
}
