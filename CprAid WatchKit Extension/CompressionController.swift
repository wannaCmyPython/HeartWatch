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

class CompressionController: WKInterfaceController {
    
    //MARK: properties
    @IBOutlet weak var depthLabel: WKInterfaceLabel!
    @IBOutlet weak var depthColor: WKInterfaceImage!
    @IBOutlet weak var paceLabel: WKInterfaceLabel!
    @IBOutlet weak var paceColor: WKInterfaceImage!
    
    private var timer = Timer()
    private var cprWrapper : CPRWrapper! = nil
    private var timerRunning = false
    var isViewable = false
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let wrapper = context as? CPRWrapper {
            cprWrapper = wrapper
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        isViewable = true
        
        print("activating CompressionController")
        self.depthLabel.setText("Depth: --")
        self.paceLabel.setText("Pace: --")
        self.depthColor.setImageNamed("red");
        self.paceColor.setImageNamed("red");
        
        cprWrapper.setController(self, "CompressionController", "Compressions")
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
        print("comp deac called")
        super.didDeactivate()
        isViewable = false
        if (cprWrapper.inForeground()){
            print("comp back arrow pressed")
            timerRunning = false
            //invalidateTimer()
        }
    }
    
    func invalidateTimer(){
        print("ending compressions")
        timerRunning = false
        DispatchQueue.global(qos: .userInitiated).async {
            self.timer.invalidate()
        }
    }
    
    func startMotion(){
        // Configure a timer to fetch the motion data.
        os_log("starting motion timer")
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
