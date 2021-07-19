//
//  Cache.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

/// Safe Dictionary
struct Cache<K: Hashable, V> {
    typealias Element = V
    private let queue = DispatchQueue(label: "com.cache.queue")
    private var cache: [K: V] = [:]
    
    var count: Int { queue.sync { cache.count } }
    var values: Dictionary<K, V>.Values {
        get { queue.sync { cache.values } }
        set { queue.sync { cache.values = newValue} }
    }
    
    subscript(key: K) -> V? {
        set {
            queue.sync { cache[key] = newValue }
        }
        get {
            queue.sync { cache[key] }
        }
    }
    
    mutating func removeValue(forKey key: K) -> V? {
        queue.sync { cache.removeValue(forKey: key) }
    }
    
    mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        queue.sync { cache.removeAll(keepingCapacity: keepCapacity) }
    }
}
