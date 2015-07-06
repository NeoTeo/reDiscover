//
//  NSCollectionViewFlowLayout+colsAndRows.swift
//  reDiscover
//
//  Created by Teo on 06/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation

//: Extend the flow layout to provide column and row coordinates of its layout.
extension NSCollectionViewFlowLayout {
    
    func colsAndRowsFromLayout() -> (Int, Int) {
        let contSize = collectionViewContentSize()
        let iSpacing = minimumInteritemSpacing
        let lSpacing = minimumLineSpacing
        let inset = sectionInset
        
        let cols = Int(ceil((contSize.width - (inset.left + inset.right)) / (itemSize.width+iSpacing)))
        let rows = Int(ceil((contSize.height - (inset.top + inset.bottom)) / (itemSize.height+lSpacing)))
        return (cols, rows)
    }
    
}