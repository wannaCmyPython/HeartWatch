//
//  Breath.swift
//  CprAid WatchKit Extension
//
//  Created by Daniel Greenberg on 11/7/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import os
import WatchConnectivity

class BreathWrapper {
    
    //instance
    private var numBreaths : Double;
    private let inhaleTime : Int;
    private let exhaleTime : Int;
    private let totalBreaths : Double;
    private let breathVals : HKActivitySummary;
    private var breathPause : Bool;
    
    init(){
        numBreaths = 0.0
        inhaleTime = 180
        exhaleTime = 120
        totalBreaths = 2.0
        breathVals = HKActivitySummary()
        breathVals.activeEnergyBurnedGoal = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: Double(exhaleTime))
        breathVals.appleExerciseTimeGoal = HKQuantity(unit: HKUnit.second(), doubleValue: totalBreaths)
        breathVals.appleStandHoursGoal = HKQuantity(unit: HKUnit.count(), doubleValue: Double(inhaleTime))
        breathPause = true
    }
    
    func getBreathData(_ counter : Int) -> [Any] {
        var retVal : [Any] = [false, "Exhale"]
        
        var correctedCounter = 0.0
        var breathTime = 0.0
        var pauseTime = 0.0
        if (!self.breathPause) {
            correctedCounter = Double(counter%self.exhaleTime)
            breathTime = correctedCounter
            if (correctedCounter == 0.0){
                self.numBreaths += 1.0
                WKInterfaceDevice.current().play(.click)
                self.breathPause = true
            }
        }
        else{
            correctedCounter = Double(counter%self.inhaleTime)
            retVal[1] = "Inhale"
            pauseTime = correctedCounter
            if (correctedCounter == 0.0){
                WKInterfaceDevice.current().play(.click)
                self.breathPause = false
            }
        }
        self.breathVals.activeEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: breathTime)
        self.breathVals.appleExerciseTime = HKQuantity(unit: HKUnit.second(), doubleValue: self.numBreaths)
        self.breathVals.appleStandHours = HKQuantity(unit: HKUnit.count(), doubleValue: pauseTime)
        retVal.append(self.breathVals)
        
        
        if (self.numBreaths == self.totalBreaths) {
            retVal[0] = true
        }
        
        return retVal; 
    }
    
}
