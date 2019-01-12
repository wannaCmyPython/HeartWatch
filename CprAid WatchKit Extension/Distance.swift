//
//  Distance.swift
//  CprAid WatchKit Extension
//
//  Created by Daniel Greenberg on 11/4/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import Foundation

class Distance {
    private var oldRaw = 0.0
    private var oldCorrected = 0.0
    private var oldPeak = 0.0
    private var oldOldPeak = 0.0
    private var newDist = 0.0
    
    
    func clearPeak() {
        oldCorrected = 0.0
        oldOldPeak = oldPeak
        oldPeak = newDist
    }
    
    func getDist(vel:Double) -> Double {
        newDist = 0.9*(oldCorrected + vel - oldRaw)
        oldRaw = vel
        oldCorrected = newDist
        let peakDist = (abs(newDist - oldPeak) + abs(oldPeak-oldOldPeak)) / 2.0
        return peakDist
    }
    
}
