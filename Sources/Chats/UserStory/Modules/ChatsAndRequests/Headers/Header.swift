//
//  Header.swift
//  diffibleData
//
//  Created by Arman Davidoff on 21.02.2020.
//  Copyright © 2020 Arman Davidoff. All rights reserved.
//

import UIKit

class HeaderItem: UICollectionReusableView {
    
    static let headerID = Constants.headerID
    private let title = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func config(text: String, textColor: UIColor, fontSize: CGFloat) {
        title.text = text
        title.font = UIFont(name: title.font.fontName, size: fontSize)
        title.textColor = textColor
    }
}

private extension HeaderItem {

    func setupViews() {
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
    }
    
    func setupConstraints() {
        title.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        title.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        title.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        title.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
}

private extension HeaderItem {
    struct Constants {
        static let headerID = "header"
    }
}
