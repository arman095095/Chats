//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import FirebaseFirestore
import ModelInterfaces

//MARK: FirebaseFirestore
public struct ProfileNetworkModel: ProfileNetworkModelProtocol {
    
    public var userName: String
    public var info: String
    public var sex: String
    public var imageUrl: String
    public var id: String
    public var country: String
    public var city: String
    public var birthday: String
    public var removed: Bool
    public var online: Bool
    public var lastActivity: Date?
    public var postsCount: Int
    
    public init(userName: String,
                imageName: String,
                identifier: String,
                sex: String,
                info: String,
                birthDay: String,
                country: String,
                city: String) {
        self.userName = userName
        self.info = info
        self.sex = sex
        self.imageUrl = imageName
        self.id = identifier
        self.birthday = birthDay
        self.country = country
        self.city = city
        self.removed = false
        self.online = true
        self.lastActivity = nil
        self.postsCount = 0
    }
    
    public func convertModelToDictionary() -> [String: Any] { //For send Model to Firebase as Dictionary
        var muserDictionary: [String: Any] = [ProfileURLComponents.Parameters.uid.rawValue:id]
        muserDictionary[ProfileURLComponents.Parameters.username.rawValue] = userName
        muserDictionary[ProfileURLComponents.Parameters.info.rawValue] = info
        muserDictionary[ProfileURLComponents.Parameters.sex.rawValue] = sex
        muserDictionary[ProfileURLComponents.Parameters.imageURL.rawValue] = imageUrl
        muserDictionary[ProfileURLComponents.Parameters.birthday.rawValue] = birthday
        muserDictionary[ProfileURLComponents.Parameters.country.rawValue] = country
        muserDictionary[ProfileURLComponents.Parameters.city.rawValue] = city
        muserDictionary[ProfileURLComponents.Parameters.removed.rawValue] = removed
        muserDictionary[ProfileURLComponents.Parameters.online.rawValue] = online
        muserDictionary[ProfileURLComponents.Parameters.lastActivity.rawValue] = FieldValue.serverTimestamp()
        
        return muserDictionary
    }
    
    init?(dict: [String: Any]) {
        guard let userName = dict[ProfileURLComponents.Parameters.username.rawValue] as? String,
              let info = dict[ProfileURLComponents.Parameters.info.rawValue] as? String,
              let sex = dict[ProfileURLComponents.Parameters.sex.rawValue] as? String,
              let imageURL = dict[ProfileURLComponents.Parameters.imageURL.rawValue] as? String,
              let birthDay = dict[ProfileURLComponents.Parameters.birthday.rawValue] as? String,
              let country = dict[ProfileURLComponents.Parameters.country.rawValue] as? String,
              let city = dict[ProfileURLComponents.Parameters.city.rawValue] as? String,
              let removed = dict[ProfileURLComponents.Parameters.removed.rawValue] as? Bool,
              let online = dict[ProfileURLComponents.Parameters.online.rawValue] as? Bool,
              let identifier = dict[ProfileURLComponents.Parameters.uid.rawValue] as? String else {
            return nil
        }
        let lastActivity = dict[ProfileURLComponents.Parameters.lastActivity.rawValue] as? Timestamp
        self.userName = userName
        self.info = info
        self.sex = sex
        self.imageUrl = imageURL
        self.id = identifier
        self.birthday = birthDay
        self.country = country
        self.city = city
        self.removed = removed
        self.online = online
        self.lastActivity = lastActivity?.dateValue()
        self.postsCount = 0
    }
}
