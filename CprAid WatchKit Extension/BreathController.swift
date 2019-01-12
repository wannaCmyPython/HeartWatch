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

class BreathController: WKInterfaceController {

    //instance
    private var timer = Timer()
    private var cprWrapper : CPRWrapper! = nil
    private var timerRunning = false
    var isViewable = false
    
    // IBOutlets
    @IBOutlet weak var breathRing: WKInterfaceActivityRing!
    @IBOutlet weak var breathLabel: WKInterfaceLabel!
        
        
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let wrapper = context as? CPRWrapper {
            cprWrapper = wrapper
        }
    }
        
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        print("activating BreathController")
        isViewable = true
        
        cprWrapper.setController(self, "BreathController", "Breaths")

        if (!timerRunning){
            DispatchQueue.global(qos: .userInitiated).async {
                //self.startMotion()
                self.timerRunning = true
                self.customTimer()
                
            }
        }
    }
         
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        print("breath deac called")
        super.didDeactivate()
        isViewable = false
        if (cprWrapper.inForeground()){
            print("breath back arrow pressed")
            self.timerRunning = false
            //invalidateTimer()
        }
    }
        
    func invalidateTimer(){
        print("ending breaths")
        timerRunning = false
        // can move this to main if no invalidate decided
        DispatchQueue.global(qos: .userInitiated).async {
            self.timer.invalidate()
        }
    }
        
    func startMotion(){
        // Configure a timer to fetch the motion data.
        os_log("starting breath timer")
        timerRunning = true
        self.timer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self,
                                            selector: #selector(callProcess),
                                            userInfo: nil,
                                            repeats: true)
        let runLoop = RunLoop.current
        runLoop.add(self.timer, forMode: RunLoop.Mode.default)
        runLoop.run()
    }
        
        
    @objc func callProcess(){
        if (timerRunning){
            self.cprWrapper.process()
        }
    }
    
    private func customTimer(){
        if (timerRunning){
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(16)) {
                self.customTimer()
            }
            self.cprWrapper.process()
        }
    }
    
        
        
}

