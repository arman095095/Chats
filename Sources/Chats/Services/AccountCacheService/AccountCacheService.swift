//
//  File.swift
//  
//
//  Created by Арман Чархчян on 20.05.2022.
//

import Foundation
import ModelInterfaces
import Services

protocol AccountCacheServiceProtocol {
    var storedAccount: AccountModelProtocol? { get }
    func store(accountModel: AccountModelProtocol)
}

final class AccountCacheService {

    private let coreDataService: CoreDataServiceProtocol
    private let accountID: String
    
    init(coreDataService: CoreDataServiceProtocol,
         accountID: String) {
        self.coreDataService = coreDataService
        self.accountID = accountID
    }
}

extension AccountCacheService: AccountCacheServiceProtocol {
    public var storedAccount: AccountModelProtocol? {
        guard let account = object(with: accountID) else { return nil }
        return AccountModel(account: account)
    }
    
    public func store(accountModel: AccountModelProtocol) {
        guard let account = object(with: accountID) else {
            create(accountModel: accountModel)
            return
        }
        update(account: account, model: accountModel)
    }
}

private extension AccountCacheService {
    func create(accountModel: AccountModelProtocol) {
        coreDataService.initModel(Account.self) { account in
            fillFields(account: account,
                       model: accountModel)
            account.profile = coreDataService.initModel(Profile.self, initHandler: { profile in
                fillFields(profile: profile,
                           model: accountModel.profile)
            })
        }
    }
    
    func update(account: Account, model: AccountModelProtocol) {
        coreDataService.update(account) { account in
            fillFields(account: account, model: model)
        }
        guard let profile = account.profile else { return }
        coreDataService.update(profile) { profile in
            fillFields(profile: profile,
                       model: model.profile)
        }
    }
    
    func fillFields(account: Account,
                    model: AccountModelProtocol) {
        account.blockedIDs = model.blockedIds
        account.requestIDs = model.requestIds
        account.waitingsIDs = model.waitingsIds
        account.friendIDs = model.friendIds
        account.id = model.profile.id
    }
}

private extension AccountCacheService {
    
    func object(with id: String) -> Account? {
        coreDataService.model(Account.self, id: id)
    }
    
    func fillFields(profile: Profile,
                    model: ProfileModelProtocol) {
        profile.userName = model.userName
        profile.info = model.info
        profile.sex = model.sex
        profile.imageUrl = model.imageUrl
        profile.id = model.id
        profile.country = model.country
        profile.city = model.city
        profile.birthday = model.birthday
        profile.removed = model.removed
        profile.online = model.online
        profile.lastActivity = model.lastActivity
        profile.postsCount = Int16(model.postsCount)
    }
}
