import Foundation
import Accelerate

class Velocity {
    
    private let timeInterval = 1.0 / 60.0
    private var numReadings = 0
    private var last4Values = [Double](repeating: 0.0, count: 6)
    private var wasPeak = false
    private var lastSum = 100.0;
    private var lastLastSum = 90.0;
    
    private var lastHalfCorrected = 0.0
    private var lastFullCorrected = 0.0
    private var integralVal = 0.0;
    
    
    private func weightedAverage(cur:Double) -> Double {
        return 0.75*cur + 0.25*lastHalfCorrected;
    }
    
    private func transientEmphasis(cur:Double) -> Double {
        return 0.9*(lastFullCorrected + cur - lastHalfCorrected)
    }
    
    private func getAverage(value:Double) -> Double {
        let second = transientEmphasis(cur: value)
        lastHalfCorrected = value
        return second;
    }
    
    private func integrate(value: Double) -> Double {
        let avg = (value + lastFullCorrected) / 2.0
        let delta = avg*timeInterval;
        let newIntVal = integralVal + delta;
        let returnValue = newIntVal
        integralVal = newIntVal
        lastFullCorrected = value;
        return returnValue
        
    }

    
    private func checkPeak() {
        var sum = 0.0;
        for val in last4Values{
            sum += val
        }
        sum = abs(sum)
        if (sum > lastSum) {
            if (lastSum < lastLastSum) {wasPeak = true}
        }
        lastLastSum = lastSum;
        lastSum = sum;
    }
    
    func clearPeak() {
        wasPeak = false;
        //integralVal=0.0;
        //lastHalfCorrected=0.0;
        //lastFullCorrected = 0.0;
    }
    
    func removeNoise(newVal: Double, timePassed: Bool) -> (Double, Bool) {
        //print("newVal \(newVal)");
        numReadings+=1;
        var retVal = 0.0
        //let newS = zeroSV(S:S);
        //let phaseOne = matrixMult(U:U, S:newS, VT:VT)
        let avgVal = getAverage(value: newVal)
        
        last4Values.removeFirst(1);
        last4Values.append(avgVal)
        retVal = integrate(value: avgVal)
        if (timePassed) {checkPeak()}
        return (retVal, wasPeak)
    }
}
