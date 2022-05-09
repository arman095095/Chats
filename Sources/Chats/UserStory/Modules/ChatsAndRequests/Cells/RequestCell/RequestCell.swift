//
//  WaitingChatCell.swift
//  diffibleData
//
//  Created by Arman Davidoff on 20.02.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import UIKit
import DesignSystem

protocol RequestCellViewModelProtocol {
    var id: String { get }
    var imageURL: String { get }
}

final class RequestCell: UICollectionViewCell {
    
    static var idCell: String = Constants.cellID
    private var userImageView = ImageView()
    
    func config(viewModel: RequestCellViewModelProtocol) {
        userImageView.set(imageURL: viewModel.imageURL)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: Setup UI
private extension RequestCell {
    
    func setupViews() {
        addSubview(userImageView)
        userImageView.translatesAutoresizingMaskIntoConstraints = false
        userImageView.layer.cornerRadius = Constants.requestCellHeight/2
        userImageView.clipsToBounds = true
        userImageView.sizeToFit()
        userImageView.contentMode = .scaleAspectFill
    }
    
    func setupConstraints() {
        userImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        userImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        userImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        userImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        userImageView.heightAnchor.constraint(equalToConstant: Constants.requestCellHeight).isActive = true
        userImageView.widthAnchor.constraint(equalToConstant: Constants.requestCellHeight).isActive = true
    }
}

private extension RequestCell {
    struct Constants {
        static let cellID = "RequestCell"
        static let requestCellHeight: CGFloat = 65
    }
}






