//
//  File.swift
//  
//
//  Created by Арман Чархчян on 15.05.2022.
//

import Foundation

struct MessangerChatStringFactory: MessangerChatStringFactoryProtocol {
    var textPlaceholderWriteAllowed: String = "Напишите сообщение"
    var textPlaceholderWriteNotAllowed: String = "Доступ ограничен"
}
