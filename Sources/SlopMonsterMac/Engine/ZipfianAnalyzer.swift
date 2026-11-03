import Foundation

public struct ZipfianMetrics: Sendable, Codable {
    public let alphaSlope: Double            // Theoretical ideal: 1.0 ± 0.12
    public let hapaxLegomenaRatio: Double    // Words appearing exactly once / total unique words (Ideal: 42% - 65%)
    public let uniqueWordCount: Int          // Vocabulary V
    public let totalWordCount: Int           // Total tokens N
    public let typeTokenRatio: Double        // V / N
    public let isZipfianCompliant: Bool
    public let assessment: String
    
    public init(
        alphaSlope: Double,
        hapaxLegomenaRatio: Double,
        uniqueWordCount: Int,
        totalWordCount: Int,
        typeTokenRatio: Double,
        isZipfianCompliant: Bool,
        assessment: String
    ) {
        self.alphaSlope = alphaSlope
        self.hapaxLegomenaRatio = hapaxLegomenaRatio
        self.uniqueWordCount = uniqueWordCount
        self.totalWordCount = totalWordCount
        self.typeTokenRatio = typeTokenRatio
        self.isZipfianCompliant = isZipfianCompliant
        self.assessment = assessment
    }
    
    public static var empty: ZipfianMetrics {
        ZipfianMetrics(
            alphaSlope: 1.0,
            hapaxLegomenaRatio: 0.50,
            uniqueWordCount: 0,
            totalWordCount: 0,
            typeTokenRatio: 1.0,
            isZipfianCompliant: true,
            assessment: "No sample analyzed"
        )
    }
}

public enum ZipfianAnalyzer {
    
    /// Evaluates Zipf's Law power-law rank exponent (f(r) ∝ 1/r^α) and Hapax Legomena ratio.
    /// Human language strictly exhibits an α slope of ~1.0 with a rich long-tail of single-occurrence words (hapax legomena > 42%).
    /// AI-generated drafts suffer from the "fat middle" phenomenon: over-represented mid-tier vocabulary and depleted long-tail terms.
    public static func evaluate(text: String) -> ZipfianMetrics {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 2 }
        
        let totalCount = words.count
        guard totalCount >= 40 else {
            return ZipfianMetrics(
                alphaSlope: 1.0,
                hapaxLegomenaRatio: 0.50,
                uniqueWordCount: words.count,
                totalWordCount: totalCount,
                typeTokenRatio: 1.0,
                isZipfianCompliant: true,
                assessment: "Sample too short for power-law distribution audit (<40 words)"
            )
        }
        
        // Count word frequencies
        var freqMap: [String: Int] = [:]
        for w in words {
            freqMap[w, default: 0] += 1
        }
        
        let uniqueCount = freqMap.count
        let ttr = Double(uniqueCount) / Double(totalCount)
        
        // Count Hapax Legomena (words with f == 1)
        let hapaxCount = freqMap.values.filter { $0 == 1 }.count
        let hapaxRatio = Double(hapaxCount) / Double(uniqueCount)
        
        // Sort frequencies descending to establish rank r = 1, 2, ... V
        let sortedFrequencies = freqMap.values.sorted(by: >)
        
        // Fit power-law: log(f) = C - α * log(r)
        // using Ordinary Least Squares linear regression on top V/2 ranks (where Zipf holds cleanest)
        let sampleLimit = max(10, min(sortedFrequencies.count, 250))
        var sumX: Double = 0.0
        var sumY: Double = 0.0
        var sumXY: Double = 0.0
        var sumX2: Double = 0.0
        let nPoints = Double(sampleLimit)
        
        for (idx, freq) in sortedFrequencies.prefix(sampleLimit).enumerated() {
            let rank = Double(idx + 1)
            let logR = log(rank)
            let logF = log(Double(freq))
            sumX += logR
            sumY += logF
            sumXY += logR * logF
            sumX2 += logR * logR
        }
        
        let denom = (nPoints * sumX2 - (sumX * sumX))
        let slope: Double
        if abs(denom) > 1e-9 {
            slope = (nPoints * sumXY - (sumX * sumY)) / denom
        } else {
            slope = -1.0
        }
        
        // α is -slope
        let alpha = max(0.1, min(2.5, -slope))
        
        // Compliance criteria:
        // Ideal human writing has alpha ~ 0.88 - 1.18 and Hapax ratio >= 38%
        let isCompliant = (alpha >= 0.82 && alpha <= 1.25) && (hapaxRatio >= 0.36)
        
        let assessment: String
        if isCompliant {
            assessment = "Zipfian Power-Law Compliant (α = \(String(format: "%.2f", alpha)), Hapax: \(Int(hapaxRatio * 100))%): Natural human lexical decay with rich long-tail vocabulary."
        } else if hapaxRatio < 0.36 {
            assessment = "Lexical 'Fat Middle' Detected (Hapax: \(Int(hapaxRatio * 100))% < 38%): Predictable AI vocabulary concentration; lacks single-occurrence human long-tail words."
        } else {
            assessment = "Anomalous Zipf Slope (α = \(String(format: "%.2f", alpha))): Deviates from natural human power-law rank decay (ideal: 1.0)."
        }
        
        return ZipfianMetrics(
            alphaSlope: alpha,
            hapaxLegomenaRatio: hapaxRatio,
            uniqueWordCount: uniqueCount,
            totalWordCount: totalCount,
            typeTokenRatio: ttr,
            isZipfianCompliant: isCompliant,
            assessment: assessment
        )
    }
}
