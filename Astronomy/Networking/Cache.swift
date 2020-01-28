//
//  Cache.swift
//  Astronomy
//
//  Created by Craig Swanson on 1/23/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

class Cache<Key: Hashable, Value> {
    
    private var cacheDictionary: [Key: Value] = [:]
    let backgroundQueue = DispatchQueue(label: "Cache Serial Queue")
    
    func cache(value: Value, key: Key) {
        backgroundQueue.async {
            self.cacheDictionary.updateValue(value, forKey: key)
        }
    }
    
    func value(for key: Key) -> Value? {
        return backgroundQueue.sync { () -> Value? in
            return cacheDictionary[key] ?? nil
        }
    }
}

