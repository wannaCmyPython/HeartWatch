//
//  TableViewController.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/18/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import UIKit
import os

class TableViewController: UITableViewController {

    //instance
    var cprSessions = [CPRData]()
    private var debug = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        if (debug){
            loadSampleSessions()
        }
        else{
            if let cd = loadData() {
                cprSessions = cd
            }else{
                loadSampleSessions()
            }
        }
        
        let redColor = self.navigationController?.navigationBar.tintColor
        let blackColor = self.navigationController?.navigationBar.barTintColor
        self.tableView.backgroundColor = blackColor
        self.tableView.separatorColor = redColor
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cprSessions.count // the lengths
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as? TableViewCell else {
            fatalError("could not make cell")
        }
        
        let session = cprSessions[indexPath.row] // gets the appropriate meal
        cell.dateLabel.text = session.date
        cell.descLabel.text = getSummary(session)

        // Configure the cell...

        return cell
    }
    
    private func getSummary(_ session : CPRData) -> String {
        var oddCorrection = 0
        if ((session.depths.count%2) != 0){
            oddCorrection = 1
        }
        let numFullComp = (session.depths.count / 2) + oddCorrection
        let numBreaths = session.numBreaths
        var averagePace = 0.0
        for p in session.pace {
            averagePace += p
        }
        averagePace /= Double(session.pace.count)
        let summary = "Compressions: \(numFullComp), Breaths \(numBreaths), Avg Pace: \(averagePace)"
        return summary
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            cprSessions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        switch(segue.identifier ?? "") {
            case "SessionDetail":
                guard let detailController = segue.destination as? DetailController else {
                        fatalError("Unexpected destination: \(segue.destination)")
                    }
                guard let selectedCell = sender as? TableViewCell else {
                    fatalError("Unexpected sender: \(String(describing: sender))")
                }
                guard let indexPath = tableView.indexPath(for: selectedCell) else {
                    fatalError("The selected cell is not being displayed by the table")
                }
                
                let selectedSession = cprSessions[indexPath.row]
                detailController.session = selectedSession
            default:
                let _ = 5
        }
    }
 

    //private methods
    
    private func loadSampleSessions() {
        let s1 = CPRData(v: "Child", d: "2018", dep: [5.2, 5.2, 3.1], p: [110.0, 110.0], nb: 10)
        
        cprSessions += [s1]
    }
    
    private func loadData() -> [CPRData]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: CPRData.ArchiveURL.path) as? [CPRData]
    }
    
    private func saveData() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(cprSessions, toFile: CPRData.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Meals successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save meals...", log: OSLog.default, type: .error)
        }
    }
    
}
