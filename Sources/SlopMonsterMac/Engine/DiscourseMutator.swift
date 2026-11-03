import Foundation
import NaturalLanguage

/// Implements Content Reordering and Syntactic Dependency Inversion based on the
/// UMass Amherst DIPPER research (Krishna et al., NeurIPS 2023) and structural evasion theory.
///
/// **Why this works against Turnitin, GPTZero & DeBERTa:**
/// Commercial neural classifiers evaluate sliding 50-100 token attention windows.
/// LLMs invariably structure expository paragraphs linearly:
///   [General Definition] → [Elaborative Theory] → [Functional Action] → [Optimistic Conclusion]
///
/// This predictable topic progression creates identical positional encoding patterns in Transformer
/// self-attention heads ($\text{softmax}(QK^T / \sqrt{d})$).
///
/// By reordering the discourse topology—e.g. leading with empirical caveats, shifting
/// dependent clauses to sentence-initial positions, and inverting proposition sequences—
/// the Transformer attention matrix is completely scrambled, breaking semantic embedding similarity
/// below the detection threshold.
public enum DiscourseMutator {
    
    /// Reorders discourse markers and restructures clause ordering across paragraphs.
    public static func mutateDiscourse(text: String) -> (mutatedText: String, edits: [String]) {
        var edits: [String] = []
        let paragraphs = text.components(separatedBy: "\n\n")
        var mutatedParagraphs: [String] = []
        
        for para in paragraphs {
            let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip headers, empty blocks, or code fences
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("```") || trimmed.hasPrefix("$$") {
                mutatedParagraphs.append(para)
                continue
            }
            
            let (mutatedPara, paraEdits) = mutateParagraphStructure(trimmed)
            mutatedParagraphs.append(mutatedPara)
            edits.append(contentsOf: paraEdits)
        }
        
        return (mutatedParagraphs.joined(separator: "\n\n"), edits)
    }
    
    /// Inverts clause dependencies and shuffles proposition hierarchy within a paragraph
    private static func mutateParagraphStructure(_ paragraph: String) -> (String, [String]) {
        var edits: [String] = []
        var sentences = extractSentences(paragraph)
        
        guard sentences.count >= 3 else {
            return (paragraph, [])
        }
        
        // 1. Invert conditional & causal clauses (e.g., "A because B" -> "Because B, A")
        for i in 0..<sentences.count {
            let s = sentences[i]
            if let inverted = invertCausalClause(s) {
                sentences[i] = inverted
                edits.append("Inverted clause hierarchy: shifted subordinate clause to sentence-initial position")
            }
        }
        
        // 2. Fragment Injection: If two consecutive sentences are both long (>20 words),
        // inject a short 3-5 word staccato assertion to break the metronome
        var adjustedSentences: [String] = []
        for i in 0..<sentences.count {
            adjustedSentences.append(sentences[i])
            
            if i < sentences.count - 1 {
                let w1 = sentences[i].components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                let w2 = sentences[i+1].components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                
                if w1 >= 22 && w2 >= 22 && i == 0 {
                    let staccatoBreaks = [
                        "In practice, this varies.",
                        "The constraint is real.",
                        "This distinction matters.",
                        "The reality is nuanced.",
                        "Under load, this shifts."
                    ]
                    let chosen = staccatoBreaks[abs(paragraph.hashValue) % staccatoBreaks.count]
                    adjustedSentences.append(chosen)
                    edits.append("Injected staccato cadence break: '\(chosen)' to destroy uniform sentence length CV")
                }
            }
        }
        
        // 3. Discourse Position Inversion: If paragraph starts with typical expository filler,
        // transpose the proposition order
        var workingText = adjustedSentences.joined(separator: " ")
        
        let expositoryOpeners: [(pattern: String, replacement: String)] = [
            (#"(?i)^To fully understand ([^,]+),\s*we must examine ([^.]+)\."#, "Examining $2 reveals the core mechanics of $1."),
            (#"(?i)^In order to ([^,]+),\s*the system ([^.]+)\."#, "The system $2 to $1."),
            (#"(?i)^Beyond raw ([^,]+),\s*modern distributed systems must resolve ([^.]+)\."#, "Resolving $2 presents a fundamental challenge beyond $1.")
        ]
        
        for rule in expositoryOpeners {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: []) {
                let range = NSRange(location: 0, length: (workingText as NSString).length)
                if regex.firstMatch(in: workingText, options: [], range: range) != nil {
                    workingText = regex.stringByReplacingMatches(in: workingText, options: [], range: range, withTemplate: rule.replacement)
                    edits.append("Transposed proposition topology from textbook exposition to direct assertion")
                }
            }
        }
        
        return (workingText, edits)
    }
    
    /// Inverts "Main clause because Subordinate clause" -> "Because Subordinate clause, Main clause"
    private static func invertCausalClause(_ sentence: String) -> String? {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.hasPrefix("Because") && !trimmed.hasPrefix("Although") && !trimmed.hasPrefix("Since") else {
            return nil
        }
        
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines)
        guard words.count >= 14 && words.count <= 32 else { return nil }
        
        // Look for ", because " or ", since " or ", while "
        let pattern = #"^([^,]+),\s*(because|since|although|whereas)\s+([^.!?]+)([.!?,]?)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        
        let ns = trimmed as NSString
        let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: ns.length))
        
        if let m = match, m.numberOfRanges >= 5 {
            let mainClause = ns.substring(with: m.range(at: 1))
            let connective = ns.substring(with: m.range(at: 2)).capitalized
            let subClause = ns.substring(with: m.range(at: 3))
            let punct = ns.substring(with: m.range(at: 4))
            
            // Lowercase first letter of main clause unless it is a proper noun or "I"
            let lowerMain: String
            if mainClause.hasPrefix("I ") || mainClause == "I" {
                lowerMain = mainClause
            } else if let firstChar = mainClause.first {
                lowerMain = String(firstChar).lowercased() + mainClause.dropFirst()
            } else {
                lowerMain = mainClause
            }
            
            return "\(connective) \(subClause), \(lowerMain)\(punct.isEmpty ? "." : punct)"
        }
        
        return nil
    }
    
    private static func extractSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty {
                sentences.append(s)
            }
            return true
        }
        return sentences
    }
}
