//
//  File.swift
//  
//
//  Created by Арман Чархчян on 27.05.2022.
//

import Foundation
import UIKit

protocol DispatchQueueProtocol: AnyObject {
    func async(handler: @escaping () ->())
    func sync(handler: @escaping () ->())
}

final class DispatchQueueWrapper {

    private let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }
}

extension DispatchQueueWrapper: DispatchQueueProtocol {
    func async(handler: @escaping () -> ()) {
        queue.async { handler() }
    }
    
    func sync(handler: @escaping () -> ()) {
        queue.sync { handler() }
    }
}
