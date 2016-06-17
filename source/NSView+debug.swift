//
//  NSView+debug.swift
//  reDiscover
//
//  Created by teo on 13/02/16.
//  Copyright © 2016 Teo Sartori. All rights reserved.
//

import Cocoa

extension NSView {
    private func _printAllSubviews(_ indentString: String) {
        Swift.print(indentString+"This view is: \(self)")
        for sv in self.subviews {
            sv._printAllSubviews(indentString+"  ")
        }
    }
    
    public func printAllSubviews() {
        _printAllSubviews("|")
    }
}
