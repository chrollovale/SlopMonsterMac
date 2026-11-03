import Foundation

public struct HeapsMetrics: Sendable, Codable {
    public let heapsBeta: Double              // Heaps' exponent β: V = K · N^β. Human ≈ 0.44–0.64, AI < 0.40
    public let heapsK: Double                 // Heaps' constant K
    public let vocabGrowthRate: Double        // dV/dN at final token (instantaneous vocabulary growth)
    public let isHeapsCompliant: Bool         // True if β falls in natural human range
    public let assessment: String
    
    public init(
        heapsBeta: Double,
        heapsK: Double,
        vocabGrowthRate: Double,
        isHeapsCompliant: Bool,
        assessment: String
    ) {
        self.heapsBeta = heapsBeta
        self.heapsK = heapsK
        self.vocabGrowthRate = vocabGrowthRate
        self.isHeapsCompliant = isHeapsCompliant
        self.assessment = assessment
    }
    
    public static var empty: HeapsMetrics {
        HeapsMetrics(
            heapsBeta: 0.55,
            heapsK: 1.0,
            vocabGrowthRate: 0,
            isHeapsCompliant: true,
            assessment: "Insufficient data for Heaps' Law analysis"
        )
    }
}

/// Evaluates Heaps' Law vocabulary growth rate: V(N) = K · N^β
///
/// **Mathematical Basis (Heaps 1978, Herdan 1960):**
///
/// Heaps' Law (also Herdan's Law) is the empirical observation that the number of distinct
/// word types V in a text of N tokens grows as a sublinear power law: V = K · N^β.
///
/// For natural human writing:
///   - β ≈ 0.44 – 0.64 (depending on genre and complexity)
///   - K ≈ 10 – 100
///
/// **Why AI Text Deviates:**
/// AI language models draw from a "vocabulary comfort zone" — a subset of the full vocabulary
/// that receives disproportionately high probability mass from the softmax layer. This causes:
///   1. **Premature vocabulary saturation** (β < 0.40): New words stop appearing at a rate
///      that's slower than natural text because the model keeps recycling familiar tokens.
///   2. **Flattened growth curve**: The V-vs-N curve bends downward earlier than expected.
///
/// **Algorithm:**
/// Sample V at multiple checkpoints along the token stream (N = 20, 40, 60, ..., total).
/// Fit log(V) = log(K) + β · log(N) via OLS regression.
///
/// **Detector Implication:**
/// Heaps' Law violation is complementary to Zipf's Law analysis — Zipf examines the static
/// frequency distribution; Heaps examines the dynamic growth process. Together they form a
/// complete picture of vocabulary naturalness.
public enum HeapsLawAnalyzer {
    
    public static func evaluate(text: String) -> HeapsMetrics {
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
        
        let totalN = tokens.count
        guard totalN >= 60 else {
            return HeapsMetrics(
                heapsBeta: 0.55,
                heapsK: 1.0,
                vocabGrowthRate: 0,
                isHeapsCompliant: true,
                assessment: "Sample too short for Heaps' Law analysis (<60 tokens)"
            )
        }
        
        // Sample vocabulary size V at checkpoints
        let checkpointInterval = max(10, totalN / 25) // ~25 checkpoints
        var checkpoints: [(n: Int, v: Int)] = []
        var vocab: Set<String> = []
        
        for (i, token) in tokens.enumerated() {
            vocab.insert(token)
            let n = i + 1
            if n % checkpointInterval == 0 || n == totalN {
                checkpoints.append((n: n, v: vocab.count))
            }
        }
        
        // Ensure we have the final point
        if checkpoints.last?.n != totalN {
            checkpoints.append((n: totalN, v: vocab.count))
        }
        
        guard checkpoints.count >= 4 else {
            return .empty
        }
        
        // OLS regression: log(V) = log(K) + β · log(N)
        let logN = checkpoints.map { log(Double($0.n)) }
        let logV = checkpoints.map { log(Double($0.v)) }
        
        let nPts = Double(logN.count)
        let sumX = logN.reduce(0, +)
        let sumY = logV.reduce(0, +)
        let sumXY = zip(logN, logV).reduce(0.0) { $0 + $1.0 * $1.1 }
        let sumX2 = logN.reduce(0.0) { $0 + $1 * $1 }
        
        let denom = nPts * sumX2 - sumX * sumX
        guard abs(denom) > 1e-12 else { return .empty }
        
        let beta = (nPts * sumXY - sumX * sumY) / denom
        let logK = (sumY - beta * sumX) / nPts
        let K = exp(logK)
        
        let clampedBeta = max(0.1, min(1.0, beta))
        
        // Instantaneous vocabulary growth rate at final N: dV/dN = K · β · N^(β-1)
        let growthRate = K * clampedBeta * pow(Double(totalN), clampedBeta - 1.0)
        
        // Human text: β ∈ [0.40, 0.70]. AI text often β < 0.38
        let isCompliant = clampedBeta >= 0.38 && clampedBeta <= 0.75
        
        let assessment: String
        if isCompliant {
            assessment = "Heaps' Law Compliant (β = \(String(format: "%.3f", clampedBeta)), K = \(String(format: "%.1f", K))): Vocabulary grows at a natural sublinear rate — consistent with human lexical diversity."
        } else if clampedBeta < 0.38 {
            assessment = "Premature Vocabulary Saturation (β = \(String(format: "%.3f", clampedBeta)) < 0.38): New word types appear too slowly — the 'vocabulary comfort zone' effect of AI token sampling."
        } else {
            assessment = "Anomalously Rapid Vocabulary Growth (β = \(String(format: "%.3f", clampedBeta)) > 0.75): Unusual lexical diversity growth; may indicate injected rare vocabulary."
        }
        
        return HeapsMetrics(
            heapsBeta: clampedBeta,
            heapsK: K,
            vocabGrowthRate: growthRate,
            isHeapsCompliant: isCompliant,
            assessment: assessment
        )
    }
}
