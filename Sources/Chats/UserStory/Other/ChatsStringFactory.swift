//
//  File.swift
//  
//
//  Created by Арман Чархчян on 09.05.2022.
//

import Foundation

struct ChatsStringFactory: ChatsAndRequestsStringFactoryProtocol,
                           MessangerChatStringFactoryProtocol {
    var title: String = "Чаты"
    var textPlaceholderWriteAllowed: String = "Напишите сообщение"
    var textPlaceholderWriteNotAllowed: String = "Доступ ограничен"
}
