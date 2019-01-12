//
//  ChartController.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/18/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import UIKit
import Charts

class DetailController: UIViewController {

    //IBOutlets
    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet weak var lineChart: LineChartView!
    
    @IBOutlet weak var summaryText: UITextView!

    //instance
    var session : CPRData! = nil
    private var summary = ["\u{2022} Victim Type: ", "\u{2022} # Compressions: ",
                           "\u{2022} Average Depth: ", "\u{2022} Average Pace: ",
                           "\u{2022} # Breaths: "]
    
    private let victimSpecs = ["AdultCPR": (4.5, 6.0), "ChildCPR": (3.5, 5.0)]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = session.date
        
        let depthValues = session.depths
        let paceValues = session.pace
        var counter = 1
        
        // new summary stuff here
        let (numBreaths, numComps, avgDepth, avgPace) = getSummary()
        var totalString = summary[0] + session.victim + "\n"
        totalString = totalString + summary[1] + "\(numComps)\n"
        totalString = totalString + summary[2] + String("\(avgDepth)".prefix(7)) + "\n"
        totalString = totalString + summary[3] + String("\(avgPace)".prefix(7)) + "\n"
        totalString = totalString + summary[4] + "\(numBreaths)\n"
        
        let redColor = self.navigationController?.navigationBar.tintColor
        summaryText.layer.borderColor = redColor?.cgColor
        summaryText.layer.borderWidth = 1
        summaryText.layer.cornerRadius = 4
        summaryText.text = totalString
        
        initCharts()
        
        setBarChart(values: depthValues)
        setLineChart(values: paceValues)
        // Do any additional setup after loading the view.
    }
    
    private func getSummary() -> (Int, Int, Double, Double) {
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
        var averageDepth = 0.0
        for d in session.depths {
            averageDepth += d
        }
        averageDepth /= Double(session.depths.count)
        return (numBreaths, numFullComp, averageDepth, averagePace)
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
        
        let (minComp, maxComp) = victimSpecs[session.victim]!
        
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
    
    func setBarChart(values: [Double]) {
        barChart.noDataText = "You need to provide data for the chart."
        
        var dataEntries = [BarChartDataEntry]()
        var colorEntries = [UIColor]()
        
        let (minComp, maxComp) = victimSpecs[session.victim]!
        
        var last : Double = 0.0
        let end = values.count - 1
        for i in 0..<values.count {
            let v = values[i]
            if ((i%2) != 1) {
                last = v;
                if (i != end){
                    continue;
                }
            }
            let combVal = (v + last) / 2.0
            var color = UIColor(red: 255.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            if (combVal > maxComp) {
                color = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            }
            else if (combVal > minComp) {
                color = UIColor(red: 0.0/255.0, green: 255.0/255.0, blue: 0.0/255.0, alpha: 1.0)
            }
            let dataEntry = BarChartDataEntry(x: Double(i), y: combVal)
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
    
    func setLineChart(values: [Double]) {
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
