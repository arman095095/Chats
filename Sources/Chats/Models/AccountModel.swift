//
//  AccountModel.swift
//  
//
//  Created by Арман Чархчян on 16.04.2022.
//

import Foundation
import ModelInterfaces
import Services

final class AccountModel: AccountModelProtocol {
    var blockedIds: Set<String>
    var friendIds: Set<String>
    var requestIds: Set<String>
    var waitingsIds: Set<String>
    var profile: ProfileModelProtocol
    
    init(profile: ProfileModelProtocol,
         blockedIDs: Set<String>,
         friendIds: Set<String>,
         waitingsIds: Set<String>,
         requestIds: Set<String>) {
        self.profile = profile
        self.blockedIds = blockedIDs
        self.requestIds = requestIds
        self.friendIds = friendIds
        self.waitingsIds = waitingsIds
    }
    
    init?(account: Account?) {
        guard let account = account,
              let profile = account.profile,
              let profile = ProfileModel(profile: profile) else { return nil }
        self.blockedIds = account.blockedIDs ?? []
        self.waitingsIds = account.waitingsIDs ?? []
        self.requestIds = account.requestIDs ?? []
        self.friendIds = account.friendIDs ?? []
        self.profile = profile
    }
}
