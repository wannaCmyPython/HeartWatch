//
//  Depth.swift
//  CprAid WatchKit Extension
//
//  Created by Daniel Greenberg on 11/5/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import Foundation

class Depth{
    private var oldDist = 90.0;
    private var oldOldDist = 100.0;
    private var newPeak = 0.0;
    private var curDepths = [Double](repeating: 5.5, count: 5)
    var depthColor : String = "green"
    var depthValue : Double = 5.5;
    private let minDepth : Double ;
    private let maxDepth : Double ;
    
    
    init(_ depthVals : (Double, Double)) {
        minDepth = depthVals.0
        maxDepth = depthVals.1
    }
    
    func checkPeak(nPeak: Double) -> Bool {
        newPeak = nPeak
        return (newPeak < oldDist) && (oldDist > oldOldDist)
    }
    
    func computeDepthTrend() {
        curDepths.removeFirst(1)
        curDepths.append(newPeak)
        var total = 0.0;
        // optimize
        for val in curDepths {
            total+=val
        }
        total/=5.0
        depthValue = total
        if (depthValue < 0.0) {depthValue = 0.0} // do not want negative depths
        
        if (depthValue > maxDepth) {
            depthColor = "yellow"
        }
        else if (depthValue > minDepth) {
            depthColor = "green"
        }
        else {
            depthColor = "red"
        }
    }
    
    func update() {
        oldOldDist = oldDist
        oldDist = newPeak
    }
}
