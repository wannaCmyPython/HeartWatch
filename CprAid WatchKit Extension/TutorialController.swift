//
//  TutorialController.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/9/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import WatchKit
import Foundation
import os
import HealthKit
import WatchConnectivity


class TutorialController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate {
    //IBOutlet
    @IBOutlet weak var tutorialLabel: WKInterfaceLabel!
    @IBOutlet weak var cprButton: WKInterfaceButton!
    
    // instance vars
    private var victimID = "AdultCPR"
    private var secondShow = false
    private var session : WCSession! = nil
    private let CONTROLLER_IND = 1
    
    private var backButton = true
    
    private var workout : HKWorkoutSession! = nil
    private var cprWrapper : CPRWrapper! = nil
    
    private let adultTips = """
                               \u{2022} Check the scene for hazards \n
                               \u{2022} Call 911 \n
                               \u{2022} Open airway by lifting head and tilting chin \n
                               \u{2022} Check for pulse and breath \n
                               \u{2022} If no pulse, begin CPR \n
                               \u{2022} Alternate between 30 seconds of compressions of at least 5cm at 100-120cpm and 2 rescue breaths \n
                               """ ;
    private let childTips = """
                               \u{2022} Check the scene for hazards \n
                               \u{2022} Call 911 \n
                               \u{2022} Open airway by lifting head and tilting chin \n
                               \u{2022} Check for pulse and breath \n
                               \u{2022} If no pulse, begin CPR \n
                               \u{2022} Alternate between 30 seconds of compressions of at least 4cm at 100-120cpm and 2 rescue breaths \n
                               \u{2022} For an infant, use 2 fingers for compressions \n
                               """ ;
    private var tutorialText = "meow";
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let hs = HKHealthStore()
        let healthKitTypesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]
        /*hs.requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (result, error) in
         if let error = error {
         print("error")
         }
         guard result else {
         print("error")
         return
         }
         }*/
        let wc = HKWorkoutConfiguration()
        wc.activityType = .other
        workout = try! HKWorkoutSession(healthStore: hs, configuration: wc)
        workout.delegate = self
        
        if let idString = context as? String {
            victimID = idString;
            switch idString {
            case "ChildCPR":
                tutorialText = childTips;
                print("CHILD")
            case "AdultCPR":
                tutorialText = adultTips;
                print("ADULT")
            default:
                tutorialText = adultTips;
                print("ERROR DEF")
            }
        }
        cprWrapper = CPRWrapper(victimID)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        backButton = true
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            if (session.activationState != WCSessionActivationState.activated){
                session.activate()
            }
        }
        checkFirstShow()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        // SHOULD CHECK FOR HOW DEACTIVATED
        super.didDeactivate()
        print("TUTORIAL");print("TUTORIAL");print("TUTORIAL");print("TUTORIAL");
        if (backButton) {
            print ("meow")
            if (self.session.isReachable && (self.session.activationState == WCSessionActivationState.activated)){
                //let messageOne : [String: Any] = ["controller_ind": 1, "victimID": victimID]
                //self.session.sendMessage(messageOne, replyHandler: nil, errorHandler: nil)
                let messageTwo : [String: Any] = ["controller_ind": 0, "victimID": victimID]
                self.session.sendMessage(messageTwo, replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    func checkFirstShow() {
        if (secondShow) { print ("woof"); workout.end(); cprWrapper.cleanup(); popToRootController() }
        else {
            secondShow = true
            tutorialLabel.setText(tutorialText)
        }
    }

    //Mark: wcdelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        print ("gotEem")
        backButton = false
        let intendedController = message["controller_ind"] as! Int
        if (intendedController > self.CONTROLLER_IND) {
            DispatchQueue.main.async() {
                self.workout.startActivity(with: nil)
                self.pushController(withName: "CompressionController", context: self.cprWrapper)
            }
        }
        else if (intendedController < self.CONTROLLER_IND) {
            DispatchQueue.main.async() {
                print ("mustEnd")
                self.cprWrapper.cleanup()
                self.workout.end()
                self.pop()
            }
        }
        
    }
    
    //workoutsession
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("\(toState == HKWorkoutSessionState.running)")
        print("\(toState == HKWorkoutSessionState.paused)")
        print("\(toState == HKWorkoutSessionState.ended)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("ERROR WITH SESSION")
    }
    
    @IBAction func cprPressed() {
        backButton = false
        if (session.isReachable && (session.activationState == WCSessionActivationState.activated)){
            let message : [String: Any] = ["controller_ind": 2, "victimID": victimID]
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
        
        workout.startActivity(with: nil)
        self.pushController(withName: "CompressionController", context: self.cprWrapper)
    }
    
}

