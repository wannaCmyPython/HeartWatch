//
//  TutorialController.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/10/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import UIKit
import WatchConnectivity
import os

class TutorialController: UIViewController, WCSessionDelegate {

    //outlets
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var beginButton: UIButton!
    
    //instance
    var victimID = "AdultCPR"
    private var backButton = true
    private var dataCollector : DataCollector! = nil
    private let CONTROLLER_IND = 1
    private var madeTransition = false
    private var secondShow = false
    
    private let adultTips = """
                               \u{2022} Check the scene for hazards \n
                               \u{2022} Call 911 \n
                               \u{2022} Open airway by lifting head and tilting chin \n
                               \u{2022} Check for pulse and breath \n
                               \u{2022} If no pulse, begin CPR \n
                               \u{2022} Alternate between 30 seconds of compressions of at least 5cm at 100-120cpm and 2 rescue breaths
                               """ ;
    private let childTips = """
                               \u{2022} Check the scene for hazards \n
                               \u{2022} Call 911 \n
                               \u{2022} Open airway by lifting head and tilting chin \n
                               \u{2022} Check for pulse and breath \n
                               \u{2022} If no pulse, begin CPR \n
                               \u{2022} Alternate between 30 seconds of compressions of at least 4cm at 100-120cpm and 2 rescue breaths \n
                               \u{2022} For an infant, use 2 fingers for compressions
                               """ ;
    private var tips : [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = false
        
        self.title = victimID + " Tutorial"
        
        tips = ["AdultCPR": adultTips, "ChildCPR": childTips]
        let redColor = self.navigationController?.navigationBar.tintColor
        tutorialText.layer.borderColor = redColor?.cgColor
        tutorialText.layer.borderWidth = 1
        tutorialText.layer.cornerRadius = 4
        
        beginButton.layer.borderColor = redColor?.cgColor
        beginButton.layer.borderWidth = 1
        beginButton.layer.cornerRadius = 4
        
        tutorialText.text = tips[victimID]
        
        
        dataCollector = DataCollector(victimID)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        madeTransition = false
        backButton = true
        // Do any additional setup after loading the view, typically from a nib.
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            if (session.activationState != WCSessionActivationState.activated){
                session.activate()
            }
        }
        checkFirstShow()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataCollector.saveData()
        if (backButton) {
            let session = WCSession.default
            if (session.isReachable && (session.activationState == WCSessionActivationState.activated)){
                let message : [String: Any] = ["controller_ind": 0, "victimID": victimID]
                session.sendMessage(message, replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    //MARK: wcdelagate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        if (!madeTransition) {
            backButton = false
            madeTransition = true
            let intendedController = message["controller_ind"] as! Int
            if (intendedController > self.CONTROLLER_IND) {
                //let victimID = message["victimID"] as! String
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CompressionController") as! CompressionController
                vc.victimID = victimID
                vc.dataCollector = dataCollector
                DispatchQueue.main.async() {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            else if (intendedController < self.CONTROLLER_IND) {
                DispatchQueue.main.async() {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func checkFirstShow() {
        if (secondShow) { self.navigationController?.popViewController(animated: true) }
        else { secondShow = true }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    // segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CompressionController {
            viewController.victimID = self.victimID
            viewController.dataCollector = dataCollector
        }
        backButton = false
        madeTransition = true
        let session = WCSession.default
        if (session.isReachable && (session.activationState == WCSessionActivationState.activated)){
            let message : [String: Any] = ["controller_ind": 2, "victimID": victimID]
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    
    
}
