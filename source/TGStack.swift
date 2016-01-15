//
//  TGStack.swift
//  reDiscover
//
//  Created by teo on 16/06/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Foundation


struct TGStack<T> {
    var theStack = T[]()
    let maxSize = 64
    
    init() {}
    init(size: Int) {
        maxSize = size
    }
    
    mutating func push(object: T) {
        if theStack.count == maxSize {
            theStack.removeAtIndex(0)
        }
        theStack.append(object)
    }
    
    mutating func pop() -> T? {
        if theStack.count > 0 {
            return theStack.removeLast()
        }
        return nil
    }
}