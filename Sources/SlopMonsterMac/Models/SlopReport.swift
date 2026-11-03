import Foundation
import SwiftUI

public enum SlopCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case vocab = "AI Vocabulary"
    case phrases = "AI Constructions"
    case punctuation = "Punctuation Cadence"
    case rhythm = "Rule-of-Three Rhythm"
    case proof = "Unsupported Social Proof"
    case burstiness = "Robotic Cadence"
    case watermark = "Invisible AI Watermarks"
    
    public var id: String { rawValue }
    
    public var retroBadge: String {
        switch self {
        case .vocab: return "👾 VOCAB"
        case .phrases: return "⚡ PHRASES"
        case .punctuation: return "— PUNCT"
        case .rhythm: return "3️⃣ TRICOLON"
        case .proof: return "🔢 PROOF"
        case .burstiness: return "⏱ CADENCE"
        case .watermark: return "🛡️ WATERMARK"
        }
    }
    
    public var mascotName: String {
        switch self {
        case .vocab: return "Buzzy the Fluff"
        case .phrases: return "Throaty the Cliché"
        case .punctuation: return "Dashy the Stutter"
        case .rhythm: return "Trio the Flute"
        case .proof: return "Fakie the Metric"
        case .burstiness: return "Metro the Monotone"
        case .watermark: return "Spooky the Ghost"
        }
    }
    
    public var editorialAdvice: String {
        switch self {
        case .vocab:
            return "Replace puffed-up buzzwords ('delve', 'seamless', 'leverage', 'elevate', 'tapestry', 'testament', 'foster') with concrete verbs. Often 'use', 'build', or 'show' is cleaner."
        case .phrases:
            return "Cut throat-clearing openers ('in today's fast-paced world', 'it is important to delve into', 'plays a pivotal role') and negated contrasts ('not just X, but Y'). State what happens directly."
        case .punctuation:
            return "Avoid em-dash pile-ups (2+ within 220 chars) and 4+ stacked hyphenated adjectives. Read sentences out loud to confirm natural breathing rhythm."
        case .rhythm:
            return "A 3-adjective flourish ('faster, smarter, and better') is a cadence, not an argument. One concrete technical specification beats three adjectives."
        case .proof:
            return "Never invent unverified customer or user statistics ('loved by 10,000+ users'). If the figure is real, verify evidence; otherwise leave a placeholder."
        case .burstiness:
            return "Vary your sentence lengths. Human writers mix short punchy sentences (3-6 words) with descriptive clauses. In long articles (1500+ words), break paragraph-length uniformity."
        case .watermark:
            return "Invisible zero-width Unicode characters (U+200B, U+200C, U+200D, U+2060, U+FEFF) were detected. AI models covertly embed these to watermark output under EU AI Act Article 50. Purge them to prevent detection and syntax errors."
        }
    }
    
    public var tintColor: Color {
        switch self {
        case .vocab: return .purple
        case .phrases: return .orange
        case .punctuation: return .blue
        case .rhythm: return .pink
        case .proof: return .red
        case .burstiness: return .yellow
        case .watermark: return .cyan
        }
    }
}

public struct SlopHit: Identifiable, Codable, Sendable {
    public let id: UUID
    public let category: SlopCategory
    public let label: String
    public let snippet: String
    public let rangeLocation: Int
    public let rangeLength: Int
    public let lineNumber: Int
    public let suggestion: String
    
    public init(
        id: UUID = UUID(),
        category: SlopCategory,
        label: String,
        snippet: String,
        range: NSRange,
        lineNumber: Int = 1,
        suggestion: String = ""
    ) {
        self.id = id
        self.category = category
        self.label = label
        self.snippet = snippet
        self.rangeLocation = range.location
        self.rangeLength = range.length
        self.lineNumber = lineNumber
        self.suggestion = suggestion
    }
    
    public var nsRange: NSRange {
        NSRange(location: rangeLocation, length: rangeLength)
    }
}

public struct SlopReport: Codable, Sendable {
    public let hits: [SlopHit]
    public let wordCount: Int
    public let characterCount: Int
    public let sentenceCount: Int
    public let classicScore: Int        // 0 to 5 (original SlopMonster gate)
    public let slopDensityIndex: Double // Tells per 100 words
    public let isClean: Bool
    public let sentenceLengthVariance: Double
    public let averageSentenceLength: Double
    public let estimatedReadingTimeSeconds: Int
    public let watermarkCount: Int
    public let entropyResult: ZipPyEntropyResult
    public let paragraphCount: Int
    public let paragraphLengthVariance: Double
    public let macroResilienceScore: Double // 0 - 100% long-document detection resistance
    public let zipfianMetrics: ZipfianMetrics
    public let syntaxMetrics: SyntacticComplexityMetrics
    public let hurstMetrics: HurstMetrics
    public let burstinessMetrics: BurstinessMetrics
    public let benfordMetrics: BenfordMetrics
    public let heapsMetrics: HeapsMetrics
    public let stylometricMatch: StylometricMatchReport
    
    public init(
        hits: [SlopHit],
        wordCount: Int,
        characterCount: Int,
        sentenceCount: Int,
        classicScore: Int,
        slopDensityIndex: Double,
        isClean: Bool,
        sentenceLengthVariance: Double,
        averageSentenceLength: Double,
        estimatedReadingTimeSeconds: Int,
        watermarkCount: Int = 0,
        entropyResult: ZipPyEntropyResult = .empty,
        paragraphCount: Int = 1,
        paragraphLengthVariance: Double = 0.0,
        macroResilienceScore: Double = 100.0,
        zipfianMetrics: ZipfianMetrics = .empty,
        syntaxMetrics: SyntacticComplexityMetrics = .empty,
        hurstMetrics: HurstMetrics = .empty,
        burstinessMetrics: BurstinessMetrics = .empty,
        benfordMetrics: BenfordMetrics = .empty,
        heapsMetrics: HeapsMetrics = .empty,
        stylometricMatch: StylometricMatchReport = .empty
    ) {
        self.hits = hits
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.sentenceCount = sentenceCount
        self.classicScore = classicScore
        self.slopDensityIndex = slopDensityIndex
        self.isClean = isClean
        self.sentenceLengthVariance = sentenceLengthVariance
        self.averageSentenceLength = averageSentenceLength
        self.estimatedReadingTimeSeconds = estimatedReadingTimeSeconds
        self.watermarkCount = watermarkCount
        self.entropyResult = entropyResult
        self.paragraphCount = paragraphCount
        self.paragraphLengthVariance = paragraphLengthVariance
        self.macroResilienceScore = macroResilienceScore
        self.zipfianMetrics = zipfianMetrics
        self.syntaxMetrics = syntaxMetrics
        self.hurstMetrics = hurstMetrics
        self.burstinessMetrics = burstinessMetrics
        self.benfordMetrics = benfordMetrics
        self.heapsMetrics = heapsMetrics
        self.stylometricMatch = stylometricMatch
    }
    
    public func hits(for category: SlopCategory) -> [SlopHit] {
        hits.filter { $0.category == category }
    }
    
    public static var empty: SlopReport {
        SlopReport(
            hits: [],
            wordCount: 0,
            characterCount: 0,
            sentenceCount: 0,
            classicScore: 5,
            slopDensityIndex: 0.0,
            isClean: true,
            sentenceLengthVariance: 0.0,
            averageSentenceLength: 0.0,
            estimatedReadingTimeSeconds: 0,
            watermarkCount: 0,
            entropyResult: .empty,
            paragraphCount: 1,
            paragraphLengthVariance: 0.0,
            macroResilienceScore: 100.0,
            zipfianMetrics: .empty,
            syntaxMetrics: .empty,
            hurstMetrics: .empty,
            burstinessMetrics: .empty,
            benfordMetrics: .empty,
            heapsMetrics: .empty,
            stylometricMatch: .empty
        )
    }
}
