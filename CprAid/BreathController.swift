//
//  ViewController.swift
//  CprAid
//
//  Created by Daniel Greenberg on 10/12/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import UIKit
import WatchConnectivity
import os
import HealthKitUI
import HealthKit

class BreathController: UIViewController, WCSessionDelegate {
    
    //MARK: IBOutlets
    @IBOutlet weak var totalNumLabel: UILabel!
    
    
    //instance
    var victimID = "AdultCPR"
    private var breathRing : HKActivityRingView! = nil
    private var breathVals : HKActivitySummary! = nil
    // change these to be sent over?
    private let inhaleTime = 180
    private let exhaleTime = 120
    private let totalBreaths = 2.0
    private var oldNum = 0.0
    private let CONTROLLER_IND = 3
    private var madeTransition = false
    
    var dataCollector : DataCollector! = nil
    
    
    @objc func buttonAction(sender: UIButton!) {
        print("Button tapped")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        self.title = victimID + " Breaths"
        
        breathVals = HKActivitySummary()
        breathVals.activeEnergyBurnedGoal = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: Double(exhaleTime))
        breathVals.appleExerciseTimeGoal = HKQuantity(unit: HKUnit.second(), doubleValue: totalBreaths)
        breathVals.appleStandHoursGoal = HKQuantity(unit: HKUnit.count(), doubleValue: Double(inhaleTime))
        
        var frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        frame.origin = self.view.bounds.origin;
        frame.origin.x = self.view.bounds.size.width / 2  - frame.size.width / 2;
        frame.origin.y = self.view.bounds.size.height / 2  - frame.size.height / 2 - 120;
        breathRing = HKActivityRingView(frame: frame)
        
        //button.backgroundColor = .green
        //button.setTitle("Test Button", for: .normal)
        //button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(breathRing)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        madeTransition = false
        // Do any additional setup after loading the view, typically from a nib.
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            if (session.activationState != WCSessionActivationState.activated){
                session.activate()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: wcdelagate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        let intendedController = message["controller_ind"] as! Int
        if (intendedController < self.CONTROLLER_IND) {
            if (!madeTransition) {
                madeTransition = true
                DispatchQueue.main.async() {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        else {
            if (message["values"] != nil) {
                if let vals = message["values"] as? [Double] {
                    self.breathVals.activeEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: vals[0])
                    self.breathVals.appleExerciseTime = HKQuantity(unit: HKUnit.second(), doubleValue: vals[1])
                    self.breathVals.appleStandHours = HKQuantity(unit: HKUnit.count(), doubleValue: vals[2])
                    if (oldNum != vals[1]) {
                        oldNum = vals[1]
                        dataCollector.addBreath()
                    }
                    DispatchQueue.main.async() {
                        self.breathRing.setActivitySummary(self.breathVals, animated: false)
                        self.totalNumLabel.text = "Total Number of Breaths: \(self.dataCollector.getNumBreaths())"
                    }
                }
            }
        }
        
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}

