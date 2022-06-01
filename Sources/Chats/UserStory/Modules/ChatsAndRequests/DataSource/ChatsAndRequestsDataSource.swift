//
//  File.swift
//  
//
//  Created by Арман Чархчян on 31.05.2022.
//

import UIKit
import DesignSystem

final class ChatsAndRequestsDataSource: UICollectionViewDiffableDataSource<Sections, Item> {
    init(collectionView: UICollectionView, output: ChatCellOuput) {
        super.init(collectionView: collectionView, cellProvider: {
            (collectionView, indexpath, item) -> UICollectionViewCell? in
            guard let section = Sections(rawValue: indexpath.section) else { fatalError("section not found") }
            switch section {
            case .chats :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatCell.idCell, for: indexpath) as! ChatCell
                cell.config(viewModel: item)
                cell.output = output
                return cell
            case .requests :
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RequestCell.idCell, for: indexpath) as! RequestCell
                cell.config(viewModel: item)
                return cell
            default:
                return nil
            }
        })
        self.supplementaryViewProvider = { collectionView, kind, indexpath -> UICollectionReusableView? in
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
    
    func reloadData(chats: [Item], requests: [Item]) {
        var snapshot = NSDiffableDataSourceSnapshot<Sections, Item>()
        snapshot.appendSections([.requests])
        snapshot.appendItems(requests, toSection: .requests)
        snapshot.appendSections([.chats])
        snapshot.appendItems(chats, toSection: .chats)
        snapshot.appendSections([.chatsEmpty])
        self.apply(snapshot, animatingDifferences: true)
    }
}

private extension ChatsAndRequestsDataSource {
    struct Constants {
        static let headerTextColor = UIColor.systemGray
        static let headerFontSize: CGFloat = 22
    }
}
