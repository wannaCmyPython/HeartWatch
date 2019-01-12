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
import HealthKit

class CPRWrapper: NSObject, WCSessionDelegate, WKExtensionDelegate {
    
    private var STATE : String;
    private var counter : Int;
    private var session : WCSession!;
    private var compressions : CompressionWrapper;
    private var breaths : BreathWrapper;
    private let victimID : String;
    private var curController : String;
    private var foregroundState : String;
    private var controllerRef : WKInterfaceController!;
    private let ext : WKExtension;
    private let BREATH_IND = 3
    private let COMP_IND = 2
    
    init(_ cprt: String) {
        STATE = "Compressions"
        session = nil
        counter = 0
        compressions = CompressionWrapper(cprt)
        breaths = BreathWrapper()
        victimID = cprt
        curController = "CompressionController"
        foregroundState = "foreground"
        controllerRef = nil
        ext = WKExtension.shared()
        
        super.init()
        
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            if (session.activationState != WCSessionActivationState.activated){
                session.activate()
            }
        }
        ext.delegate = self
    }
    
    func setController(_ cont : WKInterfaceController, _ controllerName : String, _ state: String) {
        controllerRef = cont
        curController = controllerName
        if (state != STATE){
            setState()
        }
    }
    
    func setState(){
        if (STATE == "Compressions"){
            STATE = "Breaths"
            counter = 0
            compressions.endUpdates()
            breaths = BreathWrapper()
        }
        else{
            STATE = "Compressions"
            counter = 0
            compressions = CompressionWrapper(victimID)
        }
    }
    
    
    func process(){
        if (STATE == "Compressions"){
            processCompressions()
        }
        else{
            processBreaths()
        }
        counter+=1
    }
    
    // can call this if ended using end button
    func sendMessage(_ message: [String: Any]){
        if (self.session.isReachable && (self.session.activationState == WCSessionActivationState.activated)){
            self.session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    /*
     need to have something to send to iOS
     need to have something to make sure timer is stopped - though I think that deactivate does this for me...?
     ^ if that is the case, need to check how deactivate is called that is the entire point therefore change some instance prop
     need to do something if it is ended on iOS while in background...
     */
    private func processCompressions(){
        // retVal = [false, self.depth.depthValue, self.pace.paceValue, self.depth.depthColor, self.pace.paceColor]
        let retVal = compressions.getCompressionData(counter)
        if let switchToBreaths = retVal[0] as? Bool {
            if (switchToBreaths) {
                setState()
                if ((foregroundState == "foreground") && (curController == "CompressionController")){
                    DispatchQueue.main.async {
                        if let compCont = self.controllerRef as? CompressionController{
                            //compCont.programatically = true;
                            compCont.invalidateTimer()
                        }
                        self.controllerRef.pushController(withName: "BreathController", context: self)
                    }
                }
                DispatchQueue.main.async {
                    self.sendMessage(["controller_ind": self.BREATH_IND, "victimID": self.victimID])
                }
                return
            }
        }
        
        if let wasPeak = retVal[1] as? Bool {
            if (wasPeak) {
                var vals : [Double] = [-1.0, -1.0]
                if let v = retVal[2] as? [Double] {
                    vals = v
                }else{
                    print("ERROR GETTING VALS")
                }
                
                var images : [String] = ["meow", "meow"];
                if let s = retVal[3] as? [String] {
                    images = s
                }else{
                    print("ERROR GETTING STRINGS")
                }
                
                if (foregroundState == "foreground"){
                    if (curController == "CompressionController"){
                        if let compCont = controllerRef as? CompressionController {
                            if (compCont.isViewable){
                                let depthText = String("\(vals[0])".prefix(7))
                                DispatchQueue.main.async {
                                        compCont.depthLabel.setText("Depth: " + depthText)
                                        compCont.paceLabel.setText("Pace: \(vals[1])")
                                        compCont.depthColor.setImageNamed(images[0]);
                                        compCont.paceColor.setImageNamed(images[1]);
                                }
                            }
                        }
                    }
                    // may want to move this elsewhere so that change is immediate
                    else{
                        DispatchQueue.main.async {
                            if let brCont = self.controllerRef as? BreathController{
                                //brCont.programatically = true
                                brCont.invalidateTimer()
                            }
                            self.controllerRef.pop()
                        }
                    }
              }
            DispatchQueue.main.async {
                let message : [String: Any] = ["controller_ind": self.COMP_IND, "victimID": self.victimID, "depth": NSNumber(value: vals[0]), "pace": NSNumber(value: vals[1]), "depthColor": images[0], "paceColor": images[1]]
                self.sendMessage(message)
            }
                
            }
        }
    }
    
    private func processBreaths(){
        // retVal = [false, "Exhale", controller]
        let retVal = breaths.getBreathData(counter)
        
        var breathString = "meow"
        if let s = retVal[1] as? String{
            breathString = s
        }else{
            print("ERROR BREATH STRING")
        }
        
        var breathVals : HKActivitySummary! = nil
        if let v = retVal[2] as? HKActivitySummary {
            breathVals = v
        }
        
        if (foregroundState == "foreground"){
            if (curController == "BreathController"){
                if let brCont = controllerRef as? BreathController {
                    if (brCont.isViewable){
                        DispatchQueue.main.async {
                                brCont.breathRing.setActivitySummary(breathVals, animated: false)
                                brCont.breathLabel.setText(breathString)
                        }
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    if let compCont = self.controllerRef as? CompressionController{
                        //compCont.programatically = true
                        compCont.invalidateTimer()
                    }
                    self.controllerRef.pushController(withName: "BreathController", context: self)
                }
            }
        }
        // add some code here to send to iOS
        let vOne = breathVals.activeEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
        let vTwo = breathVals.appleExerciseTime.doubleValue(for: HKUnit.second())
        let vThree = breathVals.appleStandHours.doubleValue(for: HKUnit.count())
        let myVals : [Double] = [vOne, vTwo, vThree]
        DispatchQueue.main.async {
            let message : [String: Any] = ["controller_ind": self.BREATH_IND, "victimID": self.victimID, "values": myVals]
            self.sendMessage(message)
        }
        
        if let switchToCompressions = retVal[0] as? Bool {
            if (switchToCompressions) {
                setState()
                if ((foregroundState == "foreground") && (curController == "BreathController")){
                    DispatchQueue.main.async {
                        if let brCont = self.controllerRef as? BreathController{
                            //brCont.programatically = true
                            brCont.invalidateTimer()
                        }
                        self.controllerRef.pop()
                    }
                }
                DispatchQueue.main.async {
                    self.sendMessage(["controller_ind": self.COMP_IND, "victimID": self.victimID])
                }
                return
            }
        }
    }
    
    func inForeground() -> Bool {
        return foregroundState == "foreground"
    }
    
    func cleanup() {
        compressions.endUpdates()
    }
    
    //Mark: wcdelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    // must take care of this to press the button on the viewcontroller to end shit I think..?
    // or pop it... but then the other thing happens where the view is called I think...?
    // like will the willActivate be called on the parent ...? this may not be that big of an issue actually
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        /*print("received")
        self.endCPR = true;
        DispatchQueue.main.async() {
            self.pop()
        }
         */
    }
    
    func applicationDidEnterBackground(){
        print("BACKGROUND");print("BACKGROUND");print("BACKGROUND");print("BACKGROUND");print("BACKGROUND");
        foregroundState = "background"
        curController = "none"
    }
    
    func applicationWillEnterForeground() {
        print("FOREGROUND");print("FOREGROUND");print("FOREGROUND");print("FOREGROUND");print("FOREGROUND");
        foregroundState = "foreground" // must check for willActivate call I believe
        //NO - willActivate will be the thing to set the controller name! otherwise no UI happens
    }
    
}
