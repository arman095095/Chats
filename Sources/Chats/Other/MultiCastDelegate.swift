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
    private var _delegates = [DelegateNode]()
    
    var delegates: [T] {
        _delegates.compactMap { ($0.delegateNode as? T) }
    }
    
    func add(delegate: T) {
        let node = DelegateNode(node: delegate as AnyObject)
        _delegates.append(node)
    }
    
    func remove<I>(delegate: I) {
        guard let firstIndex = _delegates.firstIndex(where: { $0.delegateNode is I }) else { return }
        _delegates.remove(at: firstIndex)
        print("Успешно удален")
        print(String(describing: delegate.self))
    }
}
