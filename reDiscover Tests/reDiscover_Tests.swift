//
//  reDiscover_Tests.swift
//  reDiscover Tests
//
//  Created by Teo on 02/12/14.
//  Copyright (c) 2014 Teo Sartori. All rights reserved.
//

import Cocoa
import XCTest
import reDiscover


class reDiscover_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

    /*
    // A bit too ambitious to test. The caching requires there to exist a matrix from which to get the songIds and it doesn't.
    func testSongPool() {
        let mySongPool = TGSongPool()
        let selectionPos    = NSValue(point: NSMakePoint(10, 10))
        let speedVector     = NSValue(point: NSMakePoint(0, 0))
        let gridDims        = NSValue(point: NSMakePoint(4, 4))
        let context = ["pos":selectionPos, "spd" : speedVector, "gridDims" : gridDims]
        let theCache = NSMutableSet(array: [SongID.initWithString("one"),SongID.initWithString("two"),SongID.initWithString("three")])
        
        mySongPool.newCacheFromCache(theCache, withContext: context, andHandler: {newCacheSet in
            println("Yahoo, the new cache is: \(newCacheSet)")
        })
        
        waitForExpectationsWithTimeout(100, handler: nil)
    }
    */
}
