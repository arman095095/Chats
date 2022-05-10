//
//  File.swift
//  
//
//  Created by Арман Чархчян on 10.05.2022.
//

import Foundation

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
