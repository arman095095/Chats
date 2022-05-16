//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import UIKit
import MessageKit

struct Photo: MediaItem {
    
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    static func imageSize(ratio: Double) -> CGSize {
        let height: CGFloat = UIScreen.main.bounds.height / 3
        let width = height*CGFloat(ratio)
        return CGSize(width: width, height: height)
    }
}
