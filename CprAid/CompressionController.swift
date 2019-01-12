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

class CompressionController: UIViewController, WCSessionDelegate {
    
    //MARK: properties
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var depthImage: UIImageView!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var paceImage: UIImageView!
    @IBOutlet weak var barChart: BarChartView!
    
    @IBOutlet weak var lineChart: LineChartView!
    //instance
    var victimID = "AdultCPR"
    var dataCollector : DataCollector! = nil
    private let victimSpecs = ["AdultCPR": (4.5, 6.0), "ChildCPR": (3.5, 5.0)]
    private let CONTROLLER_IND = 2
    private var madeTransition = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        initCharts()
        
        self.title = victimID + " Compressions"
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: wcdelagate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        let intendedController = message["controller_ind"] as! Int
        if (intendedController > self.CONTROLLER_IND) {
            //let victimID = message["victimID"] as! String
            if (!madeTransition) {
                madeTransition = true
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "BreathController") as! BreathController
                vc.victimID = victimID
                vc.dataCollector = self.dataCollector
                DispatchQueue.main.async() {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        else if (intendedController < self.CONTROLLER_IND) {
            if (!madeTransition) {
                madeTransition = true
                DispatchQueue.main.async() {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        else {
            // may want to add code here if the values do not exist
            if (message["depth"] != nil) {
                if let depthVal = message["depth"] as? Double {
                    dataCollector.addDepth(depthVal)
                }else{
                    dataCollector.addDepth(-1.0)
                }
                if let paceVal = message["pace"] as? Double {
                    dataCollector.addPace(paceVal)
                }else{
                    dataCollector.addPace(-1.0)
                }
                DispatchQueue.main.async() {
                    if let depth = message["depth"] as? NSNumber {
                        let pace = message["pace"] as! NSNumber
                        let depthColor = message["depthColor"] as! String
                        let paceColor = message["paceColor"] as! String
                        self.depthLabel.text = "Depth: \(depth.floatValue)";
                        self.paceLabel.text = "Pace: \(pace.floatValue)";
                        self.depthImage.image = UIImage(named: depthColor)
                        self.paceImage.image = UIImage(named: paceColor)
                        self.setBarChart()
                        self.setLineChart()
                    }
                }
            }
        }
    }
    
    private func initCharts () {
        
        barChart.translatesAutoresizingMaskIntoConstraints = true
        barChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeInBounce)
        barChart.legend.enabled = false
        lineChart.translatesAutoresizingMaskIntoConstraints = true
        lineChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .easeInBounce)
        lineChart.legend.enabled = false
        
        barChart.rightAxis.axisMinimum = 0.0
        barChart.rightAxis.axisMaximum = 10.0
        
        lineChart.rightAxis.axisMinimum = 0.0
        lineChart.rightAxis.axisMaximum = 200.0
        
        let (minComp, maxComp) = victimSpecs[victimID]!
        
        let maxBar = ChartLimitLine(limit: maxComp, label: "Max Depth")
        maxBar.lineWidth = 0.5
        maxBar.lineColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        maxBar.valueTextColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        maxBar.lineDashLengths = [8.0]
        barChart.rightAxis.addLimitLine(maxBar)
        barChart.reloadInputViews()
        
        let minBar = ChartLimitLine(limit: minComp, label: "Min Depth")
        minBar.lineWidth = 0.5
        minBar.lineColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        minBar.valueTextColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        minBar.lineDashLengths = [8.0]
        barChart.rightAxis.addLimitLine(minBar)
        barChart.reloadInputViews()
        
        let maxLine = ChartLimitLine(limit: 120.0, label: "Max Pace")
        maxLine.lineWidth = 0.5
        maxLine.lineColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        maxLine.valueTextColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        maxLine.lineDashLengths = [8.0]
        lineChart.rightAxis.addLimitLine(maxLine)
        lineChart.reloadInputViews()
        
        let minLine = ChartLimitLine(limit: 100.0, label: "Min Pace")
        minLine.lineWidth = 0.5
        minLine.lineColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        minLine.valueTextColor = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        minLine.lineDashLengths = [8.0]
        lineChart.rightAxis.addLimitLine(minLine)
        lineChart.reloadInputViews()
        
        
    }
    
    func setBarChart() {
        barChart.noDataText = "You need to provide data for the chart."
        
        let values = dataCollector.getLastDepths()
        var dataEntries = [BarChartDataEntry]()
        var colorEntries = [UIColor]()
        let (minComp, maxComp) = victimSpecs[victimID]!
        
        
        for i in 0..<values.count {
            let v = values[i]
            var color = UIColor(red: 255.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            if (v > maxComp) {
                color = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            }
            else if (v > minComp) {
                color = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            }
            let dataEntry = BarChartDataEntry(x: Double(i), y: v)
            dataEntries.append(dataEntry)
            colorEntries.append(color)
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Depth Values")
        chartDataSet.colors = colorEntries
        chartDataSet.drawValuesEnabled = false
        chartDataSet.axisDependency = YAxis.AxisDependency.right
        
        let chartData = BarChartData(dataSet: chartDataSet)
        barChart.data = chartData
        barChart.setNeedsDisplay()
        
    }
    
    func setLineChart() {
        let values = dataCollector.getLastPace()
        
        lineChart.noDataText = "You need to provide data for the chart."
        
        var dataEntries = [ChartDataEntry]()
        var colorEntries = [UIColor]()
        
        
        for i in 0..<values.count {
            let v = values[i]
            var color = UIColor(red: 255.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            if (v > 120.0) {
                color = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            }
            else if (v > 100.0) {
                color = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            }
            let dataEntry = BarChartDataEntry(x: Double(i), y: v)
            dataEntries.append(dataEntry)
            colorEntries.append(color)
        }
        
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: "Pace Values")
        chartDataSet.colors = colorEntries
        chartDataSet.circleColors = colorEntries
        chartDataSet.drawValuesEnabled = false
        chartDataSet.circleRadius = 4
        chartDataSet.axisDependency = YAxis.AxisDependency.right
        
        let chartData = LineChartData(dataSet: chartDataSet)
        lineChart.data = chartData
        lineChart.setNeedsDisplay()
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }

    /* let storyboard = UIStoryboard(name: "Main", bundle: nil)
     let vc = storyboard.instantiateViewController(withIdentifier: "TutorialController")
     self.navigationController?.pushViewController(vc, animated: true) */
}

