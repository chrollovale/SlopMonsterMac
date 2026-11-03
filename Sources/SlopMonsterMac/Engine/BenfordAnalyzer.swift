import Foundation

public struct BenfordMetrics: Sendable, Codable {
    public let chiSquaredStatistic: Double     // χ² goodness-of-fit against Benford's Law
    public let meanAbsoluteDeviation: Double   // MAD from ideal Benford proportions
    public let isBenfordCompliant: Bool        // True if word frequencies obey Benford's Law
    public let observedDistribution: [Double]  // Observed proportions for digits 1-9
    public let assessment: String
    
    public init(
        chiSquaredStatistic: Double,
        meanAbsoluteDeviation: Double,
        isBenfordCompliant: Bool,
        observedDistribution: [Double],
        assessment: String
    ) {
        self.chiSquaredStatistic = chiSquaredStatistic
        self.meanAbsoluteDeviation = meanAbsoluteDeviation
        self.isBenfordCompliant = isBenfordCompliant
        self.observedDistribution = observedDistribution
        self.assessment = assessment
    }
    
    public static var empty: BenfordMetrics {
        BenfordMetrics(
            chiSquaredStatistic: 0,
            meanAbsoluteDeviation: 0,
            isBenfordCompliant: true,
            observedDistribution: Array(repeating: 0, count: 9),
            assessment: "Insufficient data for Benford analysis"
        )
    }
}

/// Evaluates whether the leading-digit distribution of word frequencies obeys Benford's Law.
///
/// **Mathematical Basis (Newcomb 1881, Benford 1938):**
///
/// Benford's Law states that in many naturally occurring datasets, the leading digit d ∈ {1,...,9}
/// appears with probability P(d) = log₁₀(1 + 1/d). This yields:
///   - d=1: 30.1%, d=2: 17.6%, d=3: 12.5%, ..., d=9: 4.6%
///
/// **Application to NLP (Piantadosi 2014, Morzy et al. 2020):**
/// Word frequency counts in natural language corpora obey Benford's Law because they span
/// multiple orders of magnitude (Zipf's Law ensures this). The frequencies of the ~V unique words
/// in a human-written document produce leading digits that follow Benford's distribution.
///
/// AI-generated text, however, exhibits an anomalous "compressed middle" in its frequency
/// distribution — too many words with frequencies starting with digits 2-4, too few starting
/// with 1 or 7-9 — because the model's soft vocabulary averaging flattens the extremes.
///
/// **Test Used:**
/// Chi-squared (χ²) goodness-of-fit test against the theoretical Benford distribution.
/// If χ² > 15.51 (df=8, α=0.05), the null hypothesis (Benford compliance) is rejected.
///
/// **Detector Implication:**
/// Benford non-compliance is a second-order statistical fingerprint that is extremely difficult
/// for AI paraphrasing to eliminate, because it emerges from the global frequency distribution
/// rather than any local phrasing pattern.
public enum BenfordAnalyzer {
    
    // Theoretical Benford probabilities for leading digits 1-9
    private static let benfordProbabilities: [Double] = [
        0.30103,  // d=1: log₁₀(2/1)
        0.17609,  // d=2: log₁₀(3/2)
        0.12494,  // d=3: log₁₀(4/3)
        0.09691,  // d=4: log₁₀(5/4)
        0.07918,  // d=5: log₁₀(6/5)
        0.06695,  // d=6: log₁₀(7/6)
        0.05799,  // d=7: log₁₀(8/7)
        0.05115,  // d=8: log₁₀(9/8)
        0.04576   // d=9: log₁₀(10/9)
    ]
    
    public static func evaluate(text: String) -> BenfordMetrics {
        // Build word frequency map
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
        
        var freqMap: [String: Int] = [:]
        for w in words {
            freqMap[w, default: 0] += 1
        }
        
        // Get all frequencies (each unique word's count)
        let frequencies = Array(freqMap.values).filter { $0 >= 1 }
        
        guard frequencies.count >= 30 else {
            return BenfordMetrics(
                chiSquaredStatistic: 0,
                meanAbsoluteDeviation: 0,
                isBenfordCompliant: true,
                observedDistribution: Array(repeating: 0, count: 9),
                assessment: "Vocabulary too small for Benford analysis (<30 unique words)"
            )
        }
        
        // Count leading digits
        var digitCounts = Array(repeating: 0, count: 9) // index 0 = digit 1, ..., index 8 = digit 9
        
        for freq in frequencies {
            let leading = leadingDigit(freq)
            if leading >= 1 && leading <= 9 {
                digitCounts[leading - 1] += 1
            }
        }
        
        let totalObserved = Double(digitCounts.reduce(0, +))
        guard totalObserved >= 20 else {
            return .empty
        }
        
        // Compute observed proportions
        let observed = digitCounts.map { Double($0) / totalObserved }
        
        // Chi-squared goodness-of-fit test
        var chiSq = 0.0
        var mad = 0.0
        for i in 0..<9 {
            let expected = benfordProbabilities[i] * totalObserved
            let diff = Double(digitCounts[i]) - expected
            if expected > 0 {
                chiSq += (diff * diff) / expected
            }
            mad += abs(observed[i] - benfordProbabilities[i])
        }
        mad /= 9.0
        
        // Critical value for χ² with df=8 at α=0.05 is 15.507
        let isCompliant = chiSq <= 15.507
        
        let assessment: String
        if isCompliant {
            assessment = "Benford Compliant (χ² = \(String(format: "%.2f", chiSq)), MAD = \(String(format: "%.4f", mad))): Word frequency leading digits follow Benford's Law — natural multi-scale vocabulary distribution."
        } else if chiSq <= 25.0 {
            assessment = "Weak Benford Deviation (χ² = \(String(format: "%.2f", chiSq))): Marginal non-compliance; frequency distribution slightly compressed compared to natural Benford curve."
        } else {
            assessment = "Benford Violation (χ² = \(String(format: "%.2f", chiSq)) >> 15.5): Word frequencies do not follow Benford's Law — anomalous 'compressed middle' consistent with AI vocabulary averaging."
        }
        
        return BenfordMetrics(
            chiSquaredStatistic: chiSq,
            meanAbsoluteDeviation: mad,
            isBenfordCompliant: isCompliant,
            observedDistribution: observed,
            assessment: assessment
        )
    }
    
    private static func leadingDigit(_ n: Int) -> Int {
        var v = abs(n)
        if v == 0 { return 0 }
        while v >= 10 { v /= 10 }
        return v
    }
}
