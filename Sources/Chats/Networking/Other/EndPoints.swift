//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation

struct URLComponents {

    enum Paths: String {
        case users
        case lookedMessages
        case typing
        case messages
        case sendedRequests
        case waitingUsers
        case friendIDs
    }

    enum Parameters: String {
        case date
        case id
        case senderID
        case adressID
        case status
        case content
        case photoURL
        case imageRatio
        case audioURL
        case audioDuration
    }
}

struct StorageURLComponents {
    
    enum Parameters: String {
        case m4a = ".m4a"
        case audioM4A = "audio/m4a"
        case imageJpeg = "image/jpeg"
    }
    
    enum Paths: String {
        case chats = "Chats"
        case audio = "audio"
    }
}

struct ProfileURLComponents {

    enum Paths: String {
        case users
        case friendIDs
        case waitingUsers
        case sendedRequests
        case blocked
        case posts
    }

    enum Parameters: String {
        case uid
        case username
        case info
        case sex
        case lastActivity
        case online
        case removed
        case imageURL
        case birthday
        case country
        case city
        case id
    }
}
