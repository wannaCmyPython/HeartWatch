//
//  DataCollector.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/18/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import Foundation
import os

class DataCollector{
    private var depths : [Double];
    private var pace : [Double];
    private var numBreaths : Int;
    private let victim : String;
    private let date : String;
    
    init(_ v: String) {
        depths = [Double]()
        pace = [Double]()
        numBreaths = 0
        victim = v
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let curDate = Date()
        date = dateFormatter.string(from: curDate)
        //let interval = date.timeIntervalSince1970
    }
    
    
    func getLastDepths() -> [Double] {
        return Array(depths.suffix(5))
    }
    
    func getLastPace() -> [Double] {
        return Array(pace.suffix(5))
    }
    
    func getTotalBreaths() -> Int {
        return numBreaths
    }
    
    func addDepth(_ val:Double) {
        depths.append(val)
    }
    
    func addPace(_ val:Double) {
        pace.append(val)
    }
    
    func addBreath() {
        numBreaths+=1
    }
    
    func getNumBreaths() -> Int {
        return numBreaths
    }
    
    private func loadData() -> [CPRData]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: CPRData.ArchiveURL.path) as? [CPRData]
    }
    
    func saveData() {
        if (depths.count > 0){
            let newData = CPRData(v: victim, d: date, dep: depths, p: pace, nb: numBreaths)
            var currentData: [CPRData] = [newData]
            if let cd = loadData() {
                currentData += cd
            }
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(currentData, toFile: CPRData.ArchiveURL.path)
            if isSuccessfulSave {
                os_log("Meals successfully saved.", log: OSLog.default, type: .debug)
            } else {
                os_log("Failed to save meals...", log: OSLog.default, type: .error)
            }
        }
    }
}
