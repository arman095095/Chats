//
//  ChatsAndRequestsInteractor.swift
//  
//
//  Created by Арман Чархчян on 08.05.2022.
//  Copyright (c) 2022 ___ORGANIZATIONNAME___. All rights reserved.
//

import UIKit

protocol ChatsAndRequestsInteractorInput: AnyObject {
    
}

protocol ChatsAndRequestsInteractorOutput: AnyObject {
    
}

final class ChatsAndRequestsInteractor {
    
    weak var output: ChatsAndRequestsInteractorOutput?
}

extension ChatsAndRequestsInteractor: ChatsAndRequestsInteractorInput {
    
}
