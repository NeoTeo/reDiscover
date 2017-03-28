//
//  NSCollectionViewFlowLayout+colsAndRows.swift
//  reDiscover
//
//  Created by Teo on 06/07/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//

import Foundation
import Cocoa

//: Extend the flow layout to provide column and row coordinates of its layout.
extension NSCollectionViewFlowLayout {
    
    func colsAndRowsFromLayout() -> (Int, Int) {
        let contSize = collectionViewContentSize
        let iSpacing = minimumInteritemSpacing
        let lSpacing = minimumLineSpacing
        let inset = sectionInset

        var cols = Int(floor((contSize.width - (inset.left + inset.right - iSpacing)) / (itemSize.width+iSpacing)))
        let rows = Int(ceil((contSize.height - (inset.top + inset.bottom)) / (itemSize.height+lSpacing)))
        
        /// Since we never compress below 1 column, if the math returns 0 we set
        /// it back to 1.
        if cols == 0 { cols = 1 }
        return (cols, rows)
    }
 
    // Convert from a column and row coordinate point to a flat index.
    func index(from gridPos: NSPoint) -> Int {

        let (cols, _) = colsAndRowsFromLayout()
        
        return Int(gridPos.y) * cols + Int(gridPos.x)
    }

}
