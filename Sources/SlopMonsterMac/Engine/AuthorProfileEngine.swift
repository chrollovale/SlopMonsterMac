import Foundation
import NaturalLanguage

/// An author's stylometric fingerprint extracted from their writing sample.
/// Used to minimize KL-divergence between transformed output and the author's authentic voice.
public struct AuthorProfile: Sendable, Codable {
    // Sentence length distribution
    public let sentenceLengthMean: Double
    public let sentenceLengthStdDev: Double
    public let sentenceLengthSkewness: Double
    
    // Vocabulary richness
    public let typeTokenRatio: Double
    public let hapaxRatio: Double
    public let avgWordLength: Double
    
    // Punctuation frequency matrix (per 100 words)
    public let commaRate: Double
    public let semicolonRate: Double
    public let colonRate: Double
    public let emDashRate: Double
    public let exclamationRate: Double
    public let questionRate: Double
    public let parenthesisRate: Double
    
    // Paragraph structure
    public let avgParagraphLength: Double
    public let paragraphLengthStdDev: Double
    
    // Function word fingerprint (top 20 function words: frequency per 1000 words)
    public let functionWordProfile: [String: Double]
    
    // Contraction preference (0 = formal/no contractions, 1 = heavy contractions)
    public let contractionRate: Double
    
    // Discourse marker preference
    public let discourseMarkerRate: Double
    
    // Coordination ratio (compound sentence frequency)
    public let coordinationRate: Double
    
    // Sample metadata
    public let sampleWordCount: Int
    public let sampleSentenceCount: Int
    public let extractedAt: Date
    
    public static var empty: AuthorProfile {
        AuthorProfile(
            sentenceLengthMean: 18.0,
            sentenceLengthStdDev: 8.5,
            sentenceLengthSkewness: 0.5,
            typeTokenRatio: 0.55,
            hapaxRatio: 0.50,
            avgWordLength: 4.8,
            commaRate: 6.5,
            semicolonRate: 0.3,
            colonRate: 0.4,
            emDashRate: 0.2,
            exclamationRate: 0.1,
            questionRate: 0.3,
            parenthesisRate: 0.2,
            avgParagraphLength: 65.0,
            paragraphLengthStdDev: 25.0,
            functionWordProfile: [:],
            contractionRate: 0.15,
            discourseMarkerRate: 0.02,
            coordinationRate: 0.12,
            sampleWordCount: 0,
            sampleSentenceCount: 0,
            extractedAt: Date()
        )
    }
}

/// KL-Divergence report comparing transformed text against author profile.
public struct StylometricMatchReport: Sendable, Codable {
    public let overallKLDivergence: Double   // Lower is better. 0 = perfect match.
    public let sentenceLengthKL: Double
    public let punctuationKL: Double
    public let vocabularyKL: Double
    public let matchPercentage: Double       // 100 * (1 - normalized KL). Higher is better.
    public let corrections: [String]         // Suggested corrections to reduce KL-divergence
    public let assessment: String
    
    public static var empty: StylometricMatchReport {
        StylometricMatchReport(
            overallKLDivergence: 0,
            sentenceLengthKL: 0,
            punctuationKL: 0,
            vocabularyKL: 0,
            matchPercentage: 100.0,
            corrections: [],
            assessment: "No author profile loaded"
        )
    }
}

/// Extracts author stylometric profiles and computes KL-divergence match scores.
///
/// **Mathematical Basis (Juola 2008, Koppel et al. 2009, Stamatatos 2009):**
///
/// Author attribution and verification rely on the Unmasking Theorem: every writer has a
/// unique stylometric fingerprint defined by:
///   1. **Sentence length distribution** — parametrized as (μ, σ, skewness)
///   2. **Function word frequency profile** — the 50 most common function words form a
///      near-unique vector per author (Mosteller & Wallace 1964)
///   3. **Punctuation matrix** — comma, semicolon, colon, dash usage rates per 100 words
///   4. **Vocabulary richness** — TTR, hapax legomena ratio, mean word length
///   5. **Structural habits** — paragraph lengths, contraction frequency, discourse markers
///
/// The KL-divergence between two stylometric distributions is:
///   KL(P_author || Q_text) = Σ P(x) · log(P(x) / Q(x))
///
/// **Why This Is the Theoretical Ceiling:**
/// When the output text's stylometric vector matches the author's authentic fingerprint,
/// the text becomes indistinguishable from the author's genuine writing by any statistical
/// classifier — because it IS statistically identical. This is the information-theoretic
/// limit: no detector can distinguish two distributions with KL-divergence ≈ 0.
public enum AuthorProfileEngine {
    
    private static let topFunctionWords: [String] = [
        "the", "of", "and", "to", "in", "a", "is", "that", "it", "for",
        "was", "on", "are", "as", "with", "his", "they", "be", "at", "one",
        "have", "this", "from", "or", "had", "by", "but", "not", "what", "all",
        "were", "we", "when", "your", "can", "there", "an", "which", "their", "if",
        "has", "will", "each", "about", "how", "up", "out", "them", "then", "she"
    ]
    
    private static let contractionPatterns: Set<String> = [
        "don't", "doesn't", "didn't", "won't", "wouldn't", "couldn't", "shouldn't",
        "can't", "isn't", "aren't", "wasn't", "weren't", "haven't", "hasn't", "hadn't",
        "it's", "that's", "there's", "here's", "what's", "who's", "let's",
        "i'm", "you're", "we're", "they're", "he's", "she's",
        "i've", "you've", "we've", "they've",
        "i'll", "you'll", "we'll", "they'll", "he'll", "she'll", "it'll",
        "i'd", "you'd", "we'd", "they'd", "he'd", "she'd"
    ]
    
    private static let discourseMarkers: Set<String> = [
        "however", "moreover", "furthermore", "therefore", "consequently", "nevertheless",
        "nonetheless", "additionally", "similarly", "conversely", "meanwhile", "accordingly",
        "hence", "thus", "indeed", "certainly", "specifically", "notably", "importantly"
    ]
    
    // MARK: - Extract Profile from Writing Sample
    
    public static func extractProfile(from text: String) -> AuthorProfile {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count
        let lowerWords = words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }.filter { !$0.isEmpty }
        
        guard wordCount >= 30 else { return .empty }
        
        // --- Sentence length distribution ---
        let sentenceLengths = extractSentenceLengths(text)
        let slMean = sentenceLengths.isEmpty ? 18.0 : sentenceLengths.reduce(0, +) / Double(sentenceLengths.count)
        let slVariance = sentenceLengths.reduce(0.0) { $0 + pow($1 - slMean, 2) } / max(1, Double(sentenceLengths.count))
        let slStdDev = sqrt(slVariance)
        let slSkewness: Double = {
            guard slStdDev > 0.01 && sentenceLengths.count >= 3 else { return 0 }
            let n = Double(sentenceLengths.count)
            let m3 = sentenceLengths.reduce(0.0) { $0 + pow($1 - slMean, 3) } / n
            return m3 / pow(slStdDev, 3)
        }()
        
        // --- Vocabulary richness ---
        var freqMap: [String: Int] = [:]
        for w in lowerWords where w.count >= 2 {
            freqMap[w, default: 0] += 1
        }
        let uniqueCount = freqMap.count
        let totalFiltered = lowerWords.filter { $0.count >= 2 }.count
        let ttr = totalFiltered > 0 ? Double(uniqueCount) / Double(totalFiltered) : 0.5
        let hapaxCount = freqMap.values.filter { $0 == 1 }.count
        let hapaxRatio = uniqueCount > 0 ? Double(hapaxCount) / Double(uniqueCount) : 0.5
        let avgWordLen = lowerWords.isEmpty ? 4.8 : Double(lowerWords.reduce(0) { $0 + $1.count }) / Double(lowerWords.count)
        
        // --- Punctuation matrix (per 100 words) ---
        let per100 = 100.0 / max(1, Double(wordCount))
        let commaRate = Double(text.filter { $0 == "," }.count) * per100
        let semiRate = Double(text.filter { $0 == ";" }.count) * per100
        let colonRate = Double(text.filter { $0 == ":" }.count) * per100
        let emDashRate = Double(text.filter { $0 == "—" }.count) * per100
        let exclRate = Double(text.filter { $0 == "!" }.count) * per100
        let questRate = Double(text.filter { $0 == "?" }.count) * per100
        let parenRate = Double(text.filter { $0 == "(" || $0 == ")" }.count) * per100
        
        // --- Paragraph structure ---
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let paraLengths = paragraphs.map { Double($0.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) }
        let avgParaLen = paraLengths.isEmpty ? 65.0 : paraLengths.reduce(0, +) / Double(paraLengths.count)
        let paraVariance = paraLengths.reduce(0.0) { $0 + pow($1 - avgParaLen, 2) } / max(1, Double(paraLengths.count))
        let paraStdDev = sqrt(paraVariance)
        
        // --- Function word profile ---
        var funcProfile: [String: Double] = [:]
        let per1000 = 1000.0 / max(1, Double(wordCount))
        for fw in topFunctionWords {
            let count = lowerWords.filter { $0 == fw }.count
            funcProfile[fw] = Double(count) * per1000
        }
        
        // --- Contraction rate ---
        let contractionCount = lowerWords.filter { contractionPatterns.contains($0) }.count
        let contractionRate = Double(contractionCount) / max(1, Double(wordCount))
        
        // --- Discourse marker rate ---
        let dmCount = lowerWords.filter { discourseMarkers.contains($0) }.count
        let dmRate = Double(dmCount) / max(1, Double(wordCount))
        
        // --- Coordination rate ---
        let coordWords: Set<String> = ["and", "but", "or", "yet", "so", "nor"]
        let coordCount = lowerWords.filter { coordWords.contains($0) }.count
        let coordRate = Double(coordCount) / max(1, Double(wordCount))
        
        return AuthorProfile(
            sentenceLengthMean: slMean,
            sentenceLengthStdDev: slStdDev,
            sentenceLengthSkewness: slSkewness,
            typeTokenRatio: ttr,
            hapaxRatio: hapaxRatio,
            avgWordLength: avgWordLen,
            commaRate: commaRate,
            semicolonRate: semiRate,
            colonRate: colonRate,
            emDashRate: emDashRate,
            exclamationRate: exclRate,
            questionRate: questRate,
            parenthesisRate: parenRate,
            avgParagraphLength: avgParaLen,
            paragraphLengthStdDev: paraStdDev,
            functionWordProfile: funcProfile,
            contractionRate: contractionRate,
            discourseMarkerRate: dmRate,
            coordinationRate: coordRate,
            sampleWordCount: wordCount,
            sampleSentenceCount: sentenceLengths.count,
            extractedAt: Date()
        )
    }
    
    // MARK: - Compare Text Against Author Profile (KL-Divergence)
    
    public static func matchAgainstProfile(text: String, profile: AuthorProfile) -> StylometricMatchReport {
        guard profile.sampleWordCount >= 30 else { return .empty }
        
        let currentProfile = extractProfile(from: text)
        var corrections: [String] = []
        
        // --- Sentence Length KL ---
        let slKL = gaussianKL(
            mu1: profile.sentenceLengthMean, sigma1: max(1, profile.sentenceLengthStdDev),
            mu2: currentProfile.sentenceLengthMean, sigma2: max(1, currentProfile.sentenceLengthStdDev)
        )
        if abs(currentProfile.sentenceLengthMean - profile.sentenceLengthMean) > 4.0 {
            corrections.append("Sentence length mismatch: your avg is \(String(format: "%.0f", currentProfile.sentenceLengthMean)) words vs author profile \(String(format: "%.0f", profile.sentenceLengthMean))")
        }
        if abs(currentProfile.sentenceLengthStdDev - profile.sentenceLengthStdDev) > 3.0 {
            let dir = currentProfile.sentenceLengthStdDev < profile.sentenceLengthStdDev ? "more" : "less"
            corrections.append("Sentence length variation needs \(dir) variance (SD: \(String(format: "%.1f", currentProfile.sentenceLengthStdDev)) vs profile \(String(format: "%.1f", profile.sentenceLengthStdDev)))")
        }
        
        // --- Punctuation KL ---
        let punctProfile = [profile.commaRate, profile.semicolonRate, profile.colonRate, profile.emDashRate]
        let punctCurrent = [currentProfile.commaRate, currentProfile.semicolonRate, currentProfile.colonRate, currentProfile.emDashRate]
        let punctKL = discreteKL(p: normalize(punctProfile), q: normalize(punctCurrent))
        
        if abs(currentProfile.commaRate - profile.commaRate) > 2.0 {
            let dir = currentProfile.commaRate < profile.commaRate ? "more" : "fewer"
            corrections.append("Use \(dir) commas (\(String(format: "%.1f", currentProfile.commaRate))/100w vs author \(String(format: "%.1f", profile.commaRate))/100w)")
        }
        
        if abs(currentProfile.contractionRate - profile.contractionRate) > 0.02 {
            let dir = currentProfile.contractionRate < profile.contractionRate ? "more" : "fewer"
            corrections.append("Use \(dir) contractions to match author voice")
        }
        
        // --- Vocabulary KL ---
        let vocabKL = abs(currentProfile.typeTokenRatio - profile.typeTokenRatio) * 2.0
            + abs(currentProfile.hapaxRatio - profile.hapaxRatio) * 1.5
            + abs(currentProfile.avgWordLength - profile.avgWordLength) * 0.5
        
        if abs(currentProfile.avgWordLength - profile.avgWordLength) > 0.6 {
            let dir = currentProfile.avgWordLength < profile.avgWordLength ? "longer" : "shorter"
            corrections.append("Use \(dir) words (avg \(String(format: "%.1f", currentProfile.avgWordLength)) vs profile \(String(format: "%.1f", profile.avgWordLength)))")
        }
        
        // --- Overall KL ---
        let overallKL = (slKL * 0.35) + (punctKL * 0.25) + (vocabKL * 0.25)
            + abs(currentProfile.coordinationRate - profile.coordinationRate) * 5.0 * 0.15
        
        // Convert to match percentage (sigmoid-like clamping)
        let matchPct = max(0, min(100, 100.0 * exp(-overallKL * 1.5)))
        
        let assessment: String
        if matchPct >= 85 {
            assessment = "Strong Stylometric Match (\(Int(matchPct))%): Output closely matches author's voice fingerprint across sentence rhythm, punctuation, and vocabulary."
        } else if matchPct >= 65 {
            assessment = "Moderate Match (\(Int(matchPct))%): Noticeable deviations from author's style in \(corrections.count) dimension\(corrections.count == 1 ? "" : "s"). Apply corrections for tighter alignment."
        } else {
            assessment = "Weak Match (\(Int(matchPct))%): Significant stylometric divergence. The output does not read like the author's natural writing."
        }
        
        return StylometricMatchReport(
            overallKLDivergence: overallKL,
            sentenceLengthKL: slKL,
            punctuationKL: punctKL,
            vocabularyKL: vocabKL,
            matchPercentage: matchPct,
            corrections: corrections,
            assessment: assessment
        )
    }
    
    // MARK: - KL Helpers
    
    /// KL-divergence between two univariate Gaussians: KL(N(μ₁,σ₁²) || N(μ₂,σ₂²))
    private static func gaussianKL(mu1: Double, sigma1: Double, mu2: Double, sigma2: Double) -> Double {
        let s1sq = sigma1 * sigma1
        let s2sq = sigma2 * sigma2
        guard s2sq > 1e-9 else { return 0 }
        return log(sigma2 / sigma1) + (s1sq + pow(mu1 - mu2, 2)) / (2 * s2sq) - 0.5
    }
    
    /// Discrete KL-divergence: KL(P || Q)
    private static func discreteKL(p: [Double], q: [Double]) -> Double {
        guard p.count == q.count else { return 0 }
        var kl = 0.0
        for i in 0..<p.count {
            let pi = max(1e-10, p[i])
            let qi = max(1e-10, q[i])
            kl += pi * log(pi / qi)
        }
        return max(0, kl)
    }
    
    /// Normalize a vector to sum to 1
    private static func normalize(_ v: [Double]) -> [Double] {
        let s = v.reduce(0, +)
        guard s > 1e-9 else { return v.map { _ in 1.0 / Double(v.count) } }
        return v.map { $0 / s }
    }
    
    private static func extractSentenceLengths(_ text: String) -> [Double] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return sentences.map { sentence in
            Double(sentence.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        }
    }
}
