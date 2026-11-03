import Foundation

public struct HurstMetrics: Sendable, Codable {
    public let hurstExponent: Double          // H ∈ [0, 1]: Human ≈ 0.65–0.80 (persistent), AI ≈ 0.45–0.55 (random walk)
    public let hasLongRangeMemory: Bool       // True if H ≥ 0.58 (exhibits long-range dependence)
    public let assessment: String
    
    public init(hurstExponent: Double, hasLongRangeMemory: Bool, assessment: String) {
        self.hurstExponent = hurstExponent
        self.hasLongRangeMemory = hasLongRangeMemory
        self.assessment = assessment
    }
    
    public static var empty: HurstMetrics {
        HurstMetrics(hurstExponent: 0.70, hasLongRangeMemory: true, assessment: "Insufficient data for Hurst analysis")
    }
}

/// Estimates the Hurst Exponent H via Rescaled Range (R/S) analysis on the sentence-length time series.
///
/// **Mathematical Basis:**
/// The Hurst exponent H characterizes long-range dependence in a time series:
///   - H > 0.5: Persistent (trending) — past patterns repeat. Human writing exhibits this because
///     writers build narrative arcs with correlated rhythm (short intro → long explanation → short punch).
///   - H ≈ 0.5: Random walk — no memory. AI-generated text tends toward this because each token is
///     sampled from a next-token distribution without structural planning.
///   - H < 0.5: Anti-persistent (mean-reverting) — rare in natural text.
///
/// **Algorithm (Rescaled Range / R/S Method by Hurst 1951, Mandelbrot 1968):**
///   1. Partition the sentence-length series X₁, X₂, ... Xₙ into blocks of size m.
///   2. For each block, compute the range R and standard deviation S.
///   3. Average R/S across blocks for each m.
///   4. Regress log(R/S) ~ H · log(m) to estimate H.
///
/// **Detector Implication:**
/// Turnitin's macro-level classifiers measure cadence regularity across document spans.
/// An H close to 0.5 signals machine-generated uniformity; H ≥ 0.65 signals natural long-range
/// correlations in rhythm (the "heartbeat" of human prose).
public enum HurstExponentAnalyzer {
    
    public static func evaluate(text: String) -> HurstMetrics {
        // Extract sentence lengths as time series
        let sentenceLengths = extractSentenceLengths(text)
        
        guard sentenceLengths.count >= 16 else {
            return HurstMetrics(
                hurstExponent: 0.70,
                hasLongRangeMemory: true,
                assessment: "Sample too short for Hurst analysis (need ≥16 sentences)"
            )
        }
        
        let H = computeRescaledRange(sentenceLengths)
        let clampedH = max(0.05, min(0.99, H))
        let hasMemory = clampedH >= 0.58
        
        let assessment: String
        if clampedH >= 0.65 {
            assessment = "Strong Long-Range Memory (H = \(String(format: "%.3f", clampedH))): Sentence rhythm exhibits persistent human cadence arcs — short bursts correlate with subsequent expansions."
        } else if clampedH >= 0.55 {
            assessment = "Weak Long-Range Memory (H = \(String(format: "%.3f", clampedH))): Borderline cadence correlation; some structural planning visible but rhythm may appear mechanical."
        } else {
            assessment = "Random Walk Cadence (H = \(String(format: "%.3f", clampedH)) ≈ 0.5): No long-range rhythm memory detected — consistent with AI token-by-token generation without narrative arc planning."
        }
        
        return HurstMetrics(
            hurstExponent: clampedH,
            hasLongRangeMemory: hasMemory,
            assessment: assessment
        )
    }
    
    private static func extractSentenceLengths(_ text: String) -> [Double] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return sentences.map { sentence in
            Double(sentence.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        }
    }
    
    /// Rescaled Range (R/S) analysis with OLS regression on multiple block sizes
    private static func computeRescaledRange(_ series: [Double]) -> Double {
        let n = series.count
        // Choose block sizes: powers of 2 from 4 up to n/2
        var blockSizes: [Int] = []
        var m = 4
        while m <= n / 2 {
            blockSizes.append(m)
            m *= 2
        }
        // Also add intermediate sizes for better regression fit
        m = 6
        while m <= n / 2 {
            if !blockSizes.contains(m) {
                blockSizes.append(m)
            }
            m = Int(Double(m) * 1.6)
        }
        blockSizes.sort()
        
        guard blockSizes.count >= 2 else { return 0.5 }
        
        var logM: [Double] = []
        var logRS: [Double] = []
        
        for blockSize in blockSizes {
            let numBlocks = n / blockSize
            guard numBlocks >= 1 else { continue }
            
            var rsValues: [Double] = []
            
            for b in 0..<numBlocks {
                let start = b * blockSize
                let block = Array(series[start..<(start + blockSize)])
                let mean = block.reduce(0, +) / Double(blockSize)
                
                // Cumulative deviations from mean
                var cumDev: [Double] = []
                var runSum = 0.0
                for val in block {
                    runSum += (val - mean)
                    cumDev.append(runSum)
                }
                
                let R = (cumDev.max() ?? 0) - (cumDev.min() ?? 0)
                
                // Standard deviation
                let sumSq = block.reduce(0.0) { $0 + pow($1 - mean, 2) }
                let S = sqrt(sumSq / Double(blockSize))
                
                if S > 1e-9 {
                    rsValues.append(R / S)
                }
            }
            
            if !rsValues.isEmpty {
                let avgRS = rsValues.reduce(0, +) / Double(rsValues.count)
                if avgRS > 0 {
                    logM.append(log(Double(blockSize)))
                    logRS.append(log(avgRS))
                }
            }
        }
        
        guard logM.count >= 2 else { return 0.5 }
        
        // OLS regression: log(R/S) = H * log(m) + c
        let nPts = Double(logM.count)
        let sumX = logM.reduce(0, +)
        let sumY = logRS.reduce(0, +)
        let sumXY = zip(logM, logRS).reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = logM.reduce(0.0) { $0 + $1 * $1 }
        
        let denom = nPts * sumX2 - sumX * sumX
        guard abs(denom) > 1e-12 else { return 0.5 }
        
        let H = (nPts * sumXY - sumX * sumY) / denom
        return H
    }
}
