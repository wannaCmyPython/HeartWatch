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
import Charts

class SelectController: UIViewController, WCSessionDelegate {
    
    //outlets
    @IBOutlet weak var childButton: UIButton!
    @IBOutlet weak var adultButton: UIButton!
    @IBOutlet weak var pastSessionButton: UIButton!
    
    //instance
    private let CONTROLLER_IND = 0
    private var madeTransition = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let blackColor = self.view.backgroundColor
        let redColor = childButton.tintColor
        self.navigationController?.navigationBar.tintColor = redColor
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = blackColor
        let textAttributes = [NSAttributedString.Key.foregroundColor: redColor]
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        childButton.layer.borderColor = redColor?.cgColor
        childButton.layer.borderWidth = 1
        childButton.layer.cornerRadius = 4
        adultButton.layer.borderColor = redColor?.cgColor
        adultButton.layer.borderWidth = 1
        adultButton.layer.cornerRadius = 4
        pastSessionButton.layer.borderColor = redColor?.cgColor
        pastSessionButton.layer.borderWidth = 1
        pastSessionButton.layer.cornerRadius = 4
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Do any additional setup after loading the view, typically from a nib.
        madeTransition = false
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            if (session.activationState != WCSessionActivationState.activated){
                session.activate()
            }
        }
    }
    
    //MARK: wcdelagate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        if (!madeTransition) {
            madeTransition = true
            let intendedController = message["controller_ind"] as! Int
            if (intendedController > self.CONTROLLER_IND) {
                let victimID = message["victimID"] as! String
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "TutorialController") as! TutorialController
                vc.victimID = victimID
                DispatchQueue.main.async() {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    // segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        madeTransition = true
        var victimID = "AdultCPR"
        if segue.identifier == "ChildCPR" {
            victimID = "ChildCPR"
        }
        if let viewController = segue.destination as? TutorialController {
            viewController.victimID = victimID
        }
        let session = WCSession.default
        if (session.isReachable && (session.activationState == WCSessionActivationState.activated)){
            let message : [String: Any] = ["controller_ind": 1, "victimID": victimID]
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    
    
}

