//
//  File.swift
//  
//
//  Created by Арман Чархчян on 17.05.2022.
//

import Foundation

final class DelegateNode {
    weak var delegateNode: AnyObject?
    
    init(node: AnyObject) {
        self.delegateNode = node
    }
}

final class MulticastDelegates<T> {
    private(set) var delegates = [DelegateNode]()
    
    func add(delegate: T) {
        let node = DelegateNode(node: delegate as AnyObject)
        delegates.append(node)
    }
    
    func map() -> [T] {
        delegates.compactMap {
            ($0.delegateNode as? T)
        }
    }
}
