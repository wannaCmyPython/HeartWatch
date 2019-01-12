//
//  SelectInterfaceController.swift
//  CprAid WatchKit Extension
//
//  Created by Daniel Greenberg on 11/7/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class SelectController: WKInterfaceController, WCSessionDelegate {
    
    // instance vars
    private var session : WCSession! = nil
    private let CONTROLLER_IND = 0
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            if (session.activationState != WCSessionActivationState.activated){
                session.activate()
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        // attempt to send to iOS as well when button pressed
        if (self.session.isReachable && (self.session.activationState == WCSessionActivationState.activated)){
            let message : [String: Any] = ["controller_ind": 1, "victimID": segueIdentifier]
            self.session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
        print(segueIdentifier)
        return segueIdentifier;
    }
    
    //Mark: wcdelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        let intendedController = message["controller_ind"] as! Int
        if (intendedController > self.CONTROLLER_IND) {
            let victimID = message["victimID"] as! String
            DispatchQueue.main.async() {
                self.pushController(withName: "TutorialController", context: victimID)
            }
        }
    }
}
