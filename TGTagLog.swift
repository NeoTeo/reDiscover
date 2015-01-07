//
//  TGTagLog.swift
//  reDiscover
//
//  Created by Teo on 11/12/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa

class TGTagLog: NSObject {

    func log(tag: String, message: String, args: CVarArgType... ) {

        NSLog(message,args[0])
    }
}
