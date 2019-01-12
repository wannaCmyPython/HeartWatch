//
//  File.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/18/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import UIKit
import os

class CPRData: NSObject, NSCoding {

    //MARK: Archiving Paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("cprData")
    
    //instance
    var victim : String;
    var date : String;
    var depths : [Double];
    var pace : [Double];
    var numBreaths : Int;
    
    init(v: String, d: String, dep: [Double], p: [Double], nb: Int){
        victim = v
        date = d
        depths = dep
        pace = p
        numBreaths = nb
        super.init()
    }
    
    // conform to coding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(victim, forKey: "victim")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(depths, forKey: "depths")
        aCoder.encode(pace, forKey: "pace")
        aCoder.encode(numBreaths, forKey: "numBreaths")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let v = aDecoder.decodeObject(forKey: "victim") as? String else {
            os_log("Unable to decode the victim for CPRData.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let d = aDecoder.decodeObject(forKey: "date") as? String else {
            os_log("Unable to decode the date for CPRData.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let dep = aDecoder.decodeObject(forKey: "depths") as? [Double] else {
            os_log("Unable to decode the depths for CPRData.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let p = aDecoder.decodeObject(forKey: "pace") as? [Double] else {
            os_log("Unable to decode the pace for CPRData.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let nb = aDecoder.decodeInteger(forKey: "numBreaths") // not sure why object was not working
        
        self.init(v: v, d: d, dep: dep, p:p, nb: nb)
        
    }
    
}
