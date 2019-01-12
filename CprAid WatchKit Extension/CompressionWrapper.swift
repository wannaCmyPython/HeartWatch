//
//  InterfaceController.swift
//  CPR WatchKit Extension
//
//  Created by Daniel Greenberg on 10/11/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity
import os

class CompressionWrapper {
    
    private var params : CMMotionManager;
    
    private var accX : Acceleration;
    private var accY : Acceleration;
    private var accZ : Acceleration;
    private var velX : Velocity;
    private var velY : Velocity;
    private var velZ : Velocity;
    private var distX : Distance;
    private var distY : Distance;
    private var distZ : Distance;
    
    private var pace : Pace;
    private var depth : Depth;
    
    private var counterAtDepth = 0;
    private let victimID : String ;
    private let victimSpecs = ["AdultCPR": (4.5, 6.0), "ChildCPR": (3.5, 5.0)]
    private let thirtySeconds = 0; // use this later!
    
    
    init(_ vID: String) {
        victimID = vID
        let victDepths = victimSpecs[vID]!
        
        accX = Acceleration()
        accY = Acceleration()
        accZ = Acceleration()
        velX = Velocity()
        velY = Velocity()
        velZ = Velocity()
        distX = Distance()
        distY = Distance()
        distZ = Distance()
        pace = Pace()
        depth = Depth(victDepths) 
        counterAtDepth = 0
        
        
        params = CMMotionManager()
            
        if (params.isDeviceMotionAvailable){
            self.params.deviceMotionUpdateInterval = 1.0 / 60.0
            self.params.showsDeviceMovementDisplay = false
            self.params.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        }

    }
    
    
    func getCompressionData(_ counter : Int) -> [Any] {
        var retVal : [Any]! = [false, false]
        
        if let data = self.params.deviceMotion {
            // Get the attitude relative to the magnetic north reference frame.
            if (counter%30 == 0) {WKInterfaceDevice.current().play(.click)}
            
            let enoughTimePassed = (counter-self.counterAtDepth >= 9)
            
            let cvZ = self.accZ.removeNoise(newVal: data.userAcceleration.z);
            let (cdZ, zPeak) = self.velZ.removeNoise(newVal: cvZ, timePassed: enoughTimePassed)
            
            let cvX = self.accX.removeNoise(newVal: data.userAcceleration.x);
            let (cdX, xPeak) = self.velX.removeNoise(newVal: cvX, timePassed: enoughTimePassed)
            
            let cvY = self.accY.removeNoise(newVal: data.userAcceleration.y);
            let (cdY, yPeak) = self.velY.removeNoise(newVal: cvY, timePassed: enoughTimePassed)
            
            print("COUNTER: \(counter)")
            if (counter == 1950){ // 30 seconds of actual compressions 60*30 + 150
                print("meow")
                retVal = [true]
                return retVal
            }
            
            if (counter > 150) {
                let xDist = self.distX.getDist(vel: cdX)
                let yDist = self.distY.getDist(vel: cdY)
                let zDist = self.distZ.getDist(vel: cdZ)
                let newPeak = 9.81 * 100 * (pow(xDist, 2) + pow(yDist, 2) + pow(zDist, 2)).squareRoot() // in cm
                print("\(newPeak)")
                if (yPeak || xPeak || zPeak) {
                    if ((yPeak && xPeak && zPeak) || (self.depth.checkPeak(nPeak: newPeak))) {
                        self.accX.clearPeak()
                        self.velX.clearPeak()
                        self.accY.clearPeak()
                        self.velY.clearPeak()
                        self.accZ.clearPeak()
                        self.velZ.clearPeak()
                        self.distX.clearPeak()
                        self.distY.clearPeak()
                        self.distZ.clearPeak()
                        
                        self.pace.getPace(newPeakCounter: counter)
                        self.depth.computeDepthTrend()
                        
                        print("distance \(newPeak)")
                        print("peakVals: \(yPeak) : \(xPeak) : \(zPeak)")
                        
                        let myVals : [Double] = [self.depth.depthValue, Double(self.pace.paceValue)]
                        retVal = [false, true, myVals, [self.depth.depthColor, self.pace.paceColor]]
                            
                        self.counterAtDepth = counter;
                    }
                    
                }
                self.depth.update()
            }
            
        }
        return retVal;
    }
    
    func endUpdates(){
        params.stopDeviceMotionUpdates()
    }
}
