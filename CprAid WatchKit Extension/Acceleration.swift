import Foundation
import Accelerate

class Acceleration {
    
    private let m = 65;
    private let n = 65;
    
    private let timeInterval = 1.0 / 60.0
    private var lastMRaw = [Double](repeating: 0.0, count: 65)
    private var numReadings = 0
    private var allValues = [Double]()
    
    private var matrix = [Double](repeating: 0.0, count: 4225)
    private var lastHalfCorrected = 0.0
    private var lastFullCorrected = 0.0
    private var integralVal = 0.0;

    private func svd(x:[Double]) -> (u:[Double], s:[Double], vt:[Double]) {
        var JOBZ = Int8(UnicodeScalar("A").value)
        var M = __CLPK_integer(m)
        var N = __CLPK_integer(n)
        var A = x
        var LDA = __CLPK_integer(m)
        var S = [__CLPK_doublereal](repeating: 0.0, count: min(m,n))
        var U = [__CLPK_doublereal](repeating: 0.0, count: m*m)
        var LDU = __CLPK_integer(m)
        var VT = [__CLPK_doublereal](repeating: 0.0, count: n*n)
        var LDVT = __CLPK_integer(n)
        let lwork = min(m,n)*(6+4*min(m,n))+max(m,n)
        var WORK = [__CLPK_doublereal](repeating: 0.0, count: lwork)
        var LWORK = __CLPK_integer(lwork)
        var IWORK = [__CLPK_integer](repeating: 0, count: 8*min(m,n))
        var INFO = __CLPK_integer(0)
        dgesdd_(&JOBZ, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
        //var v = [Double](repeating: 0.0, count: n*n)
        //vDSP_mtransD(VT, 1, &v, 1, vDSP_Length(n), vDSP_Length(n))
        //let stringArray = U.flatMap { String($0) }
        //let string = stringArray.joinWithSeparator("\n")
        return (U, S, VT)
    }

    private func zeroSV(S:[Double]) -> [Double]{
        var maxDiff = Double(0.0);
        var prev = S[0];
        var index = 0;
        var cutOff = 0;
        for val in S {
            let diff = prev - val;
            if (maxDiff.isLessThanOrEqualTo(diff)){
                maxDiff = diff;
                cutOff = index;
            }
            prev = val;
            index+=1;
        }
        var newS = [Double](repeating: 0.0, count: m*n)
        index = 0;
        for val in S {
            if (index >= cutOff){
                newS[index*m + index] = Double(0.0) // val
            }
            else { newS[index*m + index] = val }
            index+=1
        }
        return newS;
    }

    private func matrixMult(U:[Double], S:[Double], VT:[Double]) -> [Double]{
        var intermediate = [Double](repeating: 0.0, count: S.count)
        //vDSP_mmulD(S, 1, VT, 1, &(intermediate), 1, vDSP_Length(m), vDSP_Length(n), vDSP_Length(n))
        cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, Int32(m), Int32(n), Int32(n), 1.0, S, Int32(m), VT, Int32(n), 1.0, &(intermediate), Int32(m));
        var final = [Double](repeating: 0.0, count: S.count)
        //vDSP_mmulD(U, 1, S, 1, &(final), 1, vDSP_Length(m), vDSP_Length(n), vDSP_Length(m))
        cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, Int32(m), Int32(n), Int32(m), 1.0, U, Int32(m), intermediate, Int32(m), 1.0, &(final), Int32(m));
        return final;
    }
    
    private func weightedAverage(cur:Double) -> Double {
        return 0.9*cur + 0.1*lastHalfCorrected;
    }
    
    private func getDiagAverage(matrix:[Double], start:Int) -> Double {
        var sum = 0.0;
        let numIters = start+1;
        var index = start;
        var myStart = start;
        let inc = m-1;
        while (myStart > -1){
            sum += matrix[index];
            index+=inc
            myStart-=1
        }
        return sum / Double(numIters);
    }
    
    private func getAverage(matrix:[Double]) -> Double {
        let first = getDiagAverage(matrix: matrix, start: m-1)
        let second = weightedAverage(cur:first)
        lastHalfCorrected = first
        return second;
    }
    
    private func integrate(value: Double) {
        let avg = (value + lastFullCorrected) / 2.0
        let delta = avg*timeInterval;
        var newIntVal = integralVal + delta;
        if (newIntVal > 0.69) {newIntVal = 0.69; print("EXTREME")}
        else if (newIntVal < -0.69) {newIntVal = -0.69; print("EXTREME")}
        integralVal = newIntVal
        lastFullCorrected = value;
    }
    
    func clearPeak() {
        //allValues.removeFirst(allValues.count - 2);
        //wasPeak = false;
        integralVal = integralVal / 1.0
    }
    
    func removeNoise(newVal: Double) -> Double {
        //print("newVal \(newVal)");
        var highFilter = newVal;
        if (abs(newVal) < 0.0035) {highFilter = 0.0}
        //print("\(highFilter)")
        numReadings+=1;
            lastMRaw.removeFirst(1);
            lastMRaw.append(highFilter);
            matrix.removeFirst(m);
            matrix+=lastMRaw;
            if case (let U, let S, let VT) = svd(x:matrix) {
                let newS = zeroSV(S:S);
                let phaseOne = matrixMult(U:U, S:newS, VT:VT)
                let avgVal = getAverage(matrix: phaseOne)
                allValues.append(avgVal)
                integrate(value: avgVal)
            }
        //checkPeak();
        return integralVal
    }
}
