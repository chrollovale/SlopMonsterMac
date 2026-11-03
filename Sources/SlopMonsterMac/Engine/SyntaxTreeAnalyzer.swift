import Foundation
import NaturalLanguage

public struct SyntacticComplexityMetrics: Sendable, Codable {
    public let averageYngveDepth: Double
    public let depthVariance: Double             // Standard deviation of sentence syntactic depths (Ideal: ≥ 1.1)
    public let leftBranchingRatio: Double        // Introductory dependent clauses (human cadence signature)
    public let coordinateRatio: Double           // Compound sentence junctions
    public let isSyntacticallyDiverse: Bool
    public let assessment: String
    
    public init(
        averageYngveDepth: Double,
        depthVariance: Double,
        leftBranchingRatio: Double,
        coordinateRatio: Double,
        isSyntacticallyDiverse: Bool,
        assessment: String
    ) {
        self.averageYngveDepth = averageYngveDepth
        self.depthVariance = depthVariance
        self.leftBranchingRatio = leftBranchingRatio
        self.coordinateRatio = coordinateRatio
        self.isSyntacticallyDiverse = isSyntacticallyDiverse
        self.assessment = assessment
    }
    
    public static var empty: SyntacticComplexityMetrics {
        SyntacticComplexityMetrics(
            averageYngveDepth: 2.0,
            depthVariance: 1.5,
            leftBranchingRatio: 0.25,
            coordinateRatio: 0.25,
            isSyntacticallyDiverse: true,
            assessment: "No prose analyzed"
        )
    }
}

public enum SyntaxTreeAnalyzer {
    
    private static let subConjunctions: Set<String> = [
        "although", "because", "since", "while", "whereas", "unless", "provided",
        "inasmuch", "insofar", "notwithstanding", "supposing", "after", "before", "once"
    ]
    
    private static let relativePronouns: Set<String> = [
        "which", "who", "whom", "whose", "whereby", "wherein", "whereupon"
    ]
    
    /// Evaluates Yngve Syntactic Depth Variance and clause-branching entropy.
    /// Modern detectors analyze dependency tree shapes: AI syntax trees maintain a uniform depth (3-4),
    /// while human prose fluctuates dynamically between flat coordinate structures (depth 1) and recursive multi-clause trees (depth 6+).
    public static func evaluate(text: String) -> SyntacticComplexityMetrics {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentenceDepths: [Double] = []
        var leftBranchingCount = 0
        var coordinateCount = 0
        var totalSentences = 0
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return true }
            totalSentences += 1
            
            let words = sentence.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
            guard !words.isEmpty else { return true }
            
            // Check for left-branching introductory subordinate clause
            if let first = words.first, subConjunctions.contains(first) {
                leftBranchingCount += 1
            }
            
            // Count structural depth anchors
            var subCount = 0
            var relCount = 0
            var prepCount = 0
            let prepositions: Set<String> = ["of", "in", "to", "for", "with", "on", "at", "from", "by", "into", "through", "under"]
            
            for w in words {
                if subConjunctions.contains(w) { subCount += 1 }
                else if relativePronouns.contains(w) { relCount += 1 }
                else if prepositions.contains(w) { prepCount += 1 }
                else if w == "and" || w == "but" || w == "yet" { coordinateCount += 1 }
            }
            
            // Approximate Yngve tree depth: Base root (1) + nested subordinate clause (2 each) + relative clause (1.5 each) + prepositional chain (0.3 each)
            let estimatedDepth = 1.0 + (Double(subCount) * 1.8) + (Double(relCount) * 1.4) + (Double(prepCount) * 0.25)
            sentenceDepths.append(min(9.0, estimatedDepth))
            return true
        }
        
        guard totalSentences >= 4 else {
            return .empty
        }
        
        let avgDepth = sentenceDepths.reduce(0, +) / Double(totalSentences)
        let sumSq = sentenceDepths.reduce(0) { $0 + pow($1 - avgDepth, 2) }
        let variance = sqrt(sumSq / Double(totalSentences))
        
        let leftRatio = Double(leftBranchingCount) / Double(totalSentences)
        let coordRatio = Double(coordinateCount) / Double(totalSentences)
        
        // Human writing has variance >= 0.95 (mix of simple and deeply nested trees)
        let isDiverse = variance >= 0.90
        
        let assessment: String
        if isDiverse {
            assessment = "Syntactically Asymmetric (Tree SD: \(String(format: "%.2f", variance))): Diverse nesting depths defeat dependency-tree classifiers."
        } else {
            assessment = "Uniform Syntactic Tree Depth (Tree SD: \(String(format: "%.2f", variance)) < 0.90): Monotonous dependency tree shapes; alternate flat assertions with deep relative clauses."
        }
        
        return SyntacticComplexityMetrics(
            averageYngveDepth: avgDepth,
            depthVariance: variance,
            leftBranchingRatio: leftRatio,
            coordinateRatio: coordRatio,
            isSyntacticallyDiverse: isDiverse,
            assessment: assessment
        )
    }
}
