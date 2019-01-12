//
//  Pace.swift
//  CprAid WatchKit Extension
//
//  Created by Daniel Greenberg on 11/5/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import Foundation

class Pace {
    var paceColor = "green"
    var paceValue = 120;
    private var curPace = [Int](repeating: 120, count: 5)
    private var lastPeakCounter = 0;
    
    func getPace(newPeakCounter: Int){
        let deltaCounts = newPeakCounter - lastPeakCounter
        let newPace = 1800 / deltaCounts // 3600 div 2 since this is half we want full
        lastPeakCounter = newPeakCounter
        curPace.removeFirst(1)
        curPace.append(newPace)
        //print (curPace)
        var total = 0;
        // optimize
        for val in curPace {
            total+=val
        }
        total/=5
        paceValue = total
        if (paceValue > 120) {
            paceColor = "yellow"
        }
        else if (paceValue > 99) {
            paceColor = "green"
        }
        else {
            paceColor = "red"
        }
    }
    
}
