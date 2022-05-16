//
//  File.swift
//  
//
//  Created by Арман Чархчян on 14.05.2022.
//

import UIKit
import MessageKit

struct Audio: AudioItem {
    
    var url: URL
    
    var duration: Float
    
    var size: CGSize = CGSize(width: 250, height: 70)
}
