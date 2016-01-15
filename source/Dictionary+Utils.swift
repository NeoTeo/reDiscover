//
//  Dictionary+Utils.swift
//  
//
//  Created by Teo on 29/06/15.
//
//

import Foundation

extension Dictionary where Value : Equatable {
    
    func allKeysForValue(val: Value) -> [Key] {
        return self.filter{ $0.1 == val }.map{ $0.0 }
    }
}