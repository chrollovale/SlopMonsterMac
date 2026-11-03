import Foundation

public struct BurstinessMetrics: Sendable, Codable {
    public let fanoFactor: Double              // F = σ²/μ of content-word inter-arrival distances. Human: F >> 1 (bursty), AI: F ≈ 1 (Poisson)
    public let burstinessIndex: Double         // B = (σ - μ) / (σ + μ) ∈ [-1, 1]. Human ≈ 0.2–0.5, AI ≈ -0.1–0.1
    public let isBursty: Bool                  // True if text exhibits human-like bursty word reuse
    public let assessment: String
    
    public init(fanoFactor: Double, burstinessIndex: Double, isBursty: Bool, assessment: String) {
        self.fanoFactor = fanoFactor
        self.burstinessIndex = burstinessIndex
        self.isBursty = isBursty
        self.assessment = assessment
    }
    
    public static var empty: BurstinessMetrics {
        BurstinessMetrics(fanoFactor: 2.0, burstinessIndex: 0.3, isBursty: true, assessment: "Insufficient data for burstiness analysis")
    }
}

/// Analyzes word-reuse burstiness using the Fano Factor and Goh-Barabási Burstiness Index.
///
/// **Mathematical Basis (Altmann, Pierrehumbert & Motter 2009; Goh & Barabási 2008):**
///
/// Human writers reuse content words in bursty clusters — a word appears several times in one
/// paragraph (topical burst), then disappears for long stretches. This produces overdispersed
/// inter-arrival distances with Fano factor F = σ²/μ >> 1.
///
/// AI models, generating tokens from a smoothed next-token distribution, produce near-Poisson
/// word spacing (F ≈ 1), because each word's probability of appearing is roughly independent
/// of its recent history (the "memoryless" property of the attention mechanism's soft averaging).
///
/// **Burstiness Index B = (σ_τ - μ_τ) / (σ_τ + μ_τ):**
///   - B → 1: Maximally bursty (periodic clusters with long gaps)
///   - B → 0: Poisson (random, memoryless)
///   - B → -1: Perfectly periodic (metronomic)
///
/// **Detector Implication:**
/// Turnitin's statistical classifiers exploit the difference in word-reuse patterns between
/// human and AI text. A Fano factor close to 1 across multiple content words is a strong
/// signal of machine generation.
public enum BurstinessAnalyzer {
    
    // Exclude function words (we only want content word burstiness)
    private static let functionWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
        "being", "have", "has", "had", "do", "does", "did", "will", "would",
        "could", "should", "may", "might", "shall", "can", "not", "no",
        "this", "that", "these", "those", "it", "its", "he", "she", "they",
        "we", "you", "me", "him", "her", "us", "them", "my", "your", "his",
        "our", "their", "who", "which", "what", "where", "when", "how", "if",
        "as", "so", "than", "then", "also", "just", "only", "more", "very"
    ]
    
    public static func evaluate(text: String) -> BurstinessMetrics {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !functionWords.contains($0) }
        
        guard words.count >= 60 else {
            return BurstinessMetrics(
                fanoFactor: 2.0,
                burstinessIndex: 0.3,
                isBursty: true,
                assessment: "Sample too short for burstiness analysis (<60 content words)"
            )
        }
        
        // Build position index for each content word
        var positions: [String: [Int]] = [:]
        for (i, w) in words.enumerated() {
            positions[w, default: []].append(i)
        }
        
        // Only analyze words that appear >= 3 times (need enough inter-arrivals)
        let repeatedWords = positions.filter { $0.value.count >= 3 }
        
        guard repeatedWords.count >= 5 else {
            return BurstinessMetrics(
                fanoFactor: 2.5,
                burstinessIndex: 0.35,
                isBursty: true,
                assessment: "Vocabulary too diverse for burstiness analysis (few repeated content words)"
            )
        }
        
        var allFanos: [Double] = []
        var allBurstiness: [Double] = []
        
        for (_, posArray) in repeatedWords {
            // Compute inter-arrival distances
            var interArrivals: [Double] = []
            for i in 1..<posArray.count {
                interArrivals.append(Double(posArray[i] - posArray[i-1]))
            }
            
            guard interArrivals.count >= 2 else { continue }
            
            let mean = interArrivals.reduce(0, +) / Double(interArrivals.count)
            let variance = interArrivals.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(interArrivals.count)
            let stdDev = sqrt(variance)
            
            if mean > 1e-9 {
                let fano = variance / mean
                allFanos.append(fano)
                
                let B = (stdDev - mean) / (stdDev + mean + 1e-9)
                allBurstiness.append(B)
            }
        }
        
        guard !allFanos.isEmpty else {
            return .empty
        }
        
        let avgFano = allFanos.reduce(0, +) / Double(allFanos.count)
        let avgBurstiness = allBurstiness.reduce(0, +) / Double(allBurstiness.count)
        
        // Human text: Fano >> 1 (typically 1.8–5.0), B > 0.15
        // AI text: Fano ≈ 0.8–1.3, B ≈ -0.1–0.1
        let bursty = avgFano >= 1.4 && avgBurstiness >= 0.08
        
        let assessment: String
        if bursty {
            assessment = "Bursty Word Reuse (F = \(String(format: "%.2f", avgFano)), B = \(String(format: "%.2f", avgBurstiness))): Content words cluster in topical bursts — natural human writing pattern."
        } else if avgFano >= 1.1 {
            assessment = "Weakly Bursty (F = \(String(format: "%.2f", avgFano)), B = \(String(format: "%.2f", avgBurstiness))): Borderline word-reuse patterns; some clustering visible but rhythm may be artificially uniform."
        } else {
            assessment = "Poisson Word Spacing (F = \(String(format: "%.2f", avgFano)) ≈ 1.0, B = \(String(format: "%.2f", avgBurstiness))): Memoryless word distribution — consistent with AI next-token sampling without topical clustering."
        }
        
        return BurstinessMetrics(
            fanoFactor: avgFano,
            burstinessIndex: avgBurstiness,
            isBursty: bursty,
            assessment: assessment
        )
    }
}
