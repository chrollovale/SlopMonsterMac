import Foundation

/// Holds the output and engagement metrics for a Medium-optimized article
public struct MediumOptimizationResult: Sendable {
    public let finalizedText: String
    public let kicker: String
    public let title: String
    public let subtitle: String
    public let wordCount: Int
    public let estimatedReadMinutes: Int
    public let predictedReadRatio: Double
    public let subheadingsInjected: Int
    public let pullQuotesInjected: Int
    public let transformationsApplied: [String]
    
    public init(
        finalizedText: String,
        kicker: String,
        title: String,
        subtitle: String,
        wordCount: Int,
        estimatedReadMinutes: Int,
        predictedReadRatio: Double,
        subheadingsInjected: Int,
        pullQuotesInjected: Int,
        transformationsApplied: [String]
    ) {
        self.finalizedText = finalizedText
        self.kicker = kicker
        self.title = title
        self.subtitle = subtitle
        self.wordCount = wordCount
        self.estimatedReadMinutes = estimatedReadMinutes
        self.predictedReadRatio = predictedReadRatio
        self.subheadingsInjected = subheadingsInjected
        self.pullQuotesInjected = pullQuotesInjected
        self.transformationsApplied = transformationsApplied
    }
}

/// MediumOptimizer implements the mathematical attention and retention models
/// derived from Loewenstein (1994) information gaps, Weibull reading survival curves,
/// Sweller cognitive load buffering, and Medium's Boost curation standards.
public enum MediumOptimizer {
    
    // Average reading speed on Medium (words per minute)
    private static let wordsPerMinute: Double = 230.0
    
    // Catalog of high-curiosity, low-cognitive-load meso-loop subheadings
    private static let mesoSubheadingBank: [String] = [
        "The Production Reality Nobody Warns You About",
        "Where the Mathematical Bounds Collapse",
        "The Sub-Token Latency Tax",
        "Why Classical Heuristics Fail at Scale",
        "The Counter-Intuitive Architecture That Actually Held",
        "Unmasking the Stochastic Bottleneck",
        "The Engineering Trade-Off We Had to Make",
        "What the Real-World Benchmarks Revealed"
    ]
    
    // Rhetorical micro-loop pattern interrupts to break cognitive fatigue
    private static let microInterrupts: [(pattern: String, replacement: String)] = [
        ("Furthermore, ", "Here is where the textbook assumptions collapse: "),
        ("Moreover, ", "The catch was subtle, yet decisive: "),
        ("In addition, ", "Production telemetry showed an unexpected twist: "),
        ("It is important to remember that ", "The math reveals a stark reality: "),
        ("At the end of the day, ", "The engineering verdict is clear: "),
        ("In conclusion, ", "The final takeaway is impossible to ignore: ")
    ]
    
    /// Executes the full Medium publication-ready transformation pipeline
    public static func optimize(text: String, authorProfile: AuthorProfile? = nil) -> MediumOptimizationResult {
        var transformations: [String] = []
        
        // Step 0: Mask LaTeX equations, citations, and code blocks
        let (maskedDraft, placeholders) = TextNormalizer.maskProtectedZones(text)
        transformations.append("Shielded \(placeholders.count) LaTeX math and code blocks from alteration")
        
        var working = maskedDraft
        
        // Step 1: Detect and eradicate generic introductory throat-clearing (30-Second Attention Anchor)
        let (hookedDraft, hookApplied) = enforce30SecondHook(text: working)
        working = hookedDraft
        if hookApplied {
            transformations.append("Engineered 30-Second Attention Anchor (purged throat-clearing to eliminate infant mortality drop-off)")
        }
        
        // Step 2: Extract or synthesize Kicker, Title, and Subtitle
        let (extractedDraft, kicker, title, subtitle) = extractAndFormatHeaderHierarchy(text: working)
        working = extractedDraft
        transformations.append("Constructed Medium Typographic Hierarchy: Kicker [\(kicker)], Title [\(title)]")
        
        // Step 3: Mobile Paragraph Restructuring (Cognitive Load Decompression: 1-3 sentences per paragraph)
        let (cadencedDraft, paragraphSplits) = reformatMobileParagraphs(text: working)
        working = cadencedDraft
        if paragraphSplits > 0 {
            transformations.append("Restructured \(paragraphSplits) dense paragraph blocks into 1-3 sentence mobile reading buffers")
        }
        
        // Step 4: Meso-Loop Subheading Enforcement (~250-350 words spacing)
        let (subheadedDraft, subheadingsCount) = enforceMesoLoopSubheadings(text: working)
        working = subheadedDraft
        if subheadingsCount > 0 {
            transformations.append("Injected \(subheadingsCount) curiosity-gap meso-loop subheadings (H2) to prevent mid-article abandonment")
        }
        
        // Step 5: Pull Quote Extraction & Synthesis for Maximum Highlight Density
        let (quotedDraft, pullQuotesCount) = injectPullQuotes(text: working)
        working = quotedDraft
        if pullQuotesCount > 0 {
            transformations.append("Injected \(pullQuotesCount) high-entropy pull quotes (> blockquotes) to drive Medium reader highlights")
        }
        
        // Step 6: Micro-Loop Pattern Interrupts
        let (interruptedDraft, interruptsApplied) = injectMicroInterrupts(text: working)
        working = interruptedDraft
        if interruptsApplied > 0 {
            transformations.append("Replaced \(interruptsApplied) generic transition markers with active micro-loop pattern interrupts")
        }
        
        // Step 7: Boost-Grade Community Call to Action & Discussion Anchor
        let (ctaDraft, ctaApplied) = appendCommunityDiscussionAnchor(text: working)
        working = ctaDraft
        if ctaApplied {
            transformations.append("Installed Boost-grade Community Discussion Anchor to drive comment engagement and clap retention")
        }
        
        // Step 8: Restore Protected Zones (LaTeX Math & Code Blocks)
        let restored = TextNormalizer.restoreProtectedZones(working, placeholders: placeholders)
        
        // Step 9: Assemble final telemetry and complete Medium formatted document
        let wordCount = computeWordCount(restored)
        let readMinutes = max(1, Int(ceil(Double(wordCount) / wordsPerMinute)))
        let predictedReadRatio = calculatePredictedReadRatio(wordCount: wordCount, subheadings: subheadingsCount, pullQuotes: pullQuotesCount)
        
        // Build publication header
        var finalDocument = ""
        finalDocument += "\(kicker.uppercased())\n\n"
        finalDocument += "# \(title)\n\n"
        finalDocument += "*\(subtitle)*\n\n"
        finalDocument += "*\(readMinutes) min read · \(wordCount) words · Boost-Optimized*\n\n"
        finalDocument += "---\n\n"
        finalDocument += restored.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return MediumOptimizationResult(
            finalizedText: finalDocument,
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            wordCount: wordCount,
            estimatedReadMinutes: readMinutes,
            predictedReadRatio: predictedReadRatio,
            subheadingsInjected: subheadingsCount,
            pullQuotesInjected: pullQuotesCount,
            transformationsApplied: transformations
        )
    }
    
    // MARK: - Internal Structural Processors
    
    /// Enforces an immediate, high-stakes hook in the opening 2 sentences
    private static func enforce30SecondHook(text: String) -> (String, Bool) {
        var lines = text.components(separatedBy: .newlines)
        while let first = lines.first, first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeFirst()
        }
        guard !lines.isEmpty else { return (text, false) }
        
        var modified = false
        // Purge classic throat-clearing openers
        let throatClearers = [
            "In this article,", "In this post,", "Today, we are going to explore",
            "In today's fast-paced digital world,", "Have you ever wondered about",
            "It is widely known that", "In recent years, the rapid advancement of",
            "At its core, understanding"
        ]
        
        for i in 0..<min(5, lines.count) {
            let line = lines[i]
            for tc in throatClearers {
                if line.hasPrefix(tc) {
                    lines[i] = line.replacingOccurrences(of: tc, with: "").trimmingCharacters(in: .whitespaces)
                    // Capitalize first letter
                    if let firstChar = lines[i].first {
                        lines[i] = String(firstChar).uppercased() + lines[i].dropFirst()
                    }
                    modified = true
                }
            }
        }
        
        return (lines.joined(separator: "\n"), modified)
    }
    
    /// Extracts existing headers or synthesizes Kicker, Title, and Subtitle
    private static func extractAndFormatHeaderHierarchy(text: String) -> (cleanedBody: String, kicker: String, title: String, subtitle: String) {
        let lines = text.components(separatedBy: "\n")
        var existingKicker = "SYSTEMS & ENGINEERING // ARCHITECTURE DEEP DIVE"
        var existingTitle = "The Mathematical Limits of Modern System Design"
        var existingSubtitle = "Why classical assumptions collapse in production, and what the empirical benchmarks reveal."
        
        var headerIndicesToRemove = Set<Int>()
        var foundTitle = false
        
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Look for existing H1 (# Title)
            if trimmed.hasPrefix("# ") && !foundTitle {
                existingTitle = trimmed.replacingOccurrences(of: "# ", with: "").trimmingCharacters(in: .whitespaces)
                headerIndicesToRemove.insert(idx)
                foundTitle = true
                
                // Check if next non-empty line is an italicized subtitle or description
                var nextIdx = idx + 1
                while nextIdx < lines.count && lines[nextIdx].trimmingCharacters(in: .whitespaces).isEmpty {
                    nextIdx += 1
                }
                if nextIdx < lines.count {
                    let nextTrimmed = lines[nextIdx].trimmingCharacters(in: .whitespaces)
                    if nextTrimmed.hasPrefix("*") && nextTrimmed.hasSuffix("*") && nextTrimmed.count > 5 {
                        existingSubtitle = nextTrimmed.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                        headerIndicesToRemove.insert(nextIdx)
                    } else if !nextTrimmed.hasPrefix("#") && nextTrimmed.count < 160 && !nextTrimmed.isEmpty {
                        existingSubtitle = nextTrimmed
                        headerIndicesToRemove.insert(nextIdx)
                    }
                }
                break
            }
        }
        
        // If no explicit "# Title" was found, extract Title and Subtitle dynamically from the content
        if !foundTitle {
            var firstCandidateIdx: Int? = nil
            var secondCandidateIdx: Int? = nil
            
            for (idx, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !trimmed.hasPrefix("![") && !trimmed.hasPrefix("---") {
                    if firstCandidateIdx == nil {
                        firstCandidateIdx = idx
                    } else if secondCandidateIdx == nil {
                        secondCandidateIdx = idx
                        break
                    }
                }
            }
            
            if let fIdx = firstCandidateIdx {
                let rawFirst = lines[fIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                // Check if first line is a short heading (< 80 chars, not ending with a period)
                if rawFirst.count < 80 && !rawFirst.hasSuffix(".") {
                    existingTitle = rawFirst.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                    headerIndicesToRemove.insert(fIdx)
                    
                    if let sIdx = secondCandidateIdx {
                        let rawSecond = lines[sIdx].trimmingCharacters(in: .whitespacesAndNewlines)
                        if rawSecond.count < 140 {
                            existingSubtitle = rawSecond.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                            headerIndicesToRemove.insert(sIdx)
                        }
                    }
                } else if rawFirst.contains(":") {
                    // e.g. "Three standard-issue brain bug: Confirmation bias. Anchoring bias."
                    let colonParts = rawFirst.components(separatedBy: ":")
                    let part0 = colonParts[0].trimmingCharacters(in: .whitespaces)
                    if part0.count > 5 && part0.count < 70 {
                        existingTitle = part0
                        if colonParts.count > 1 {
                            let part1 = colonParts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                            let sentences = extractSentences(part1)
                            existingSubtitle = sentences.first ?? part1
                        }
                    }
                } else {
                    // Extract first sentence as title
                    let sentences = extractSentences(rawFirst)
                    if let firstS = sentences.first, firstS.count < 90 {
                        existingTitle = firstS.trimmingCharacters(in: CharacterSet(charactersIn: ".?! "))
                        if sentences.count > 1 {
                            existingSubtitle = sentences[1].trimmingCharacters(in: CharacterSet(charactersIn: ".?! "))
                        }
                    }
                }
            }
        }
        
        // Remove extracted header lines from the body
        var cleanedLines: [String] = []
        for (idx, line) in lines.enumerated() {
            if !headerIndicesToRemove.contains(idx) {
                cleanedLines.append(line)
            }
        }
        
        // Infer kicker domain from content keywords
        let bodyLower = text.lowercased()
        if bodyLower.contains("bias") || bodyLower.contains("cognitive") || bodyLower.contains("psychology") || bodyLower.contains("brain") || bodyLower.contains("mental") {
            existingKicker = "COGNITIVE PSYCHOLOGY // BEHAVIORAL DYNAMICS"
        } else if bodyLower.contains("latency") || bodyLower.contains("distributed") || bodyLower.contains("byzantine") || bodyLower.contains("consensus") {
            existingKicker = "DISTRIBUTED SYSTEMS // PRODUCTION BENCHMARKS"
        } else if bodyLower.contains("nlp") || bodyLower.contains("detector") || bodyLower.contains("perplexity") || bodyLower.contains("transformer") || bodyLower.contains("slop") {
            existingKicker = "APPLIED NLP // STOCHASTIC DYNAMICS"
        } else if bodyLower.contains("roof") || bodyLower.contains("contractor") || bodyLower.contains("homeowner") {
            existingKicker = "CONSTRUCTION & ARCHITECTURE // INDUSTRY REPORT"
        } else if bodyLower.contains("finance") || bodyLower.contains("market") || bodyLower.contains("invest") || bodyLower.contains("revenue") {
            existingKicker = "FINANCE & MARKETS // STRATEGIC ANALYSIS"
        } else if bodyLower.contains("algorithm") || bodyLower.contains("math") || bodyLower.contains("formula") {
            existingKicker = "COMPUTER SCIENCE // MATHEMATICAL FOUNDATIONS"
        } else {
            existingKicker = "ORIGINAL PERSPECTIVE // IN-DEPTH ANALYSIS"
        }
        
        return (cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), existingKicker, existingTitle, existingSubtitle)
    }
    
    /// Splits oversized paragraphs into 1-3 sentence mobile-friendly blocks
    private static func reformatMobileParagraphs(text: String) -> (String, Int) {
        let paragraphs = text.components(separatedBy: "\n\n")
        var formattedParagraphs: [String] = []
        var splitsCount = 0
        
        for p in paragraphs {
            let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip code blocks, headings, lists, blockquotes, and placeholders
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(">") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("1. ") || trimmed.contains("```") || trimmed.hasPrefix("«SAFE_ZONE_") {
                formattedParagraphs.append(p)
                continue
            }
            
            // Sentence splitting heuristic
            let sentences = extractSentences(trimmed)
            if sentences.count > 3 {
                // Chunk into blocks of 2 sentences
                var chunk: [String] = []
                for s in sentences {
                    chunk.append(s)
                    if chunk.count == 2 {
                        formattedParagraphs.append(chunk.joined(separator: " "))
                        chunk.removeAll()
                        splitsCount += 1
                    }
                }
                if !chunk.isEmpty {
                    formattedParagraphs.append(chunk.joined(separator: " "))
                }
            } else {
                formattedParagraphs.append(trimmed)
            }
        }
        
        return (formattedParagraphs.joined(separator: "\n\n"), splitsCount)
    }
    
    /// Injects meso-loop curiosity subheadings (H2) every 250-350 words if missing
    private static func enforceMesoLoopSubheadings(text: String) -> (String, Int) {
        let paragraphs = text.components(separatedBy: "\n\n")
        var resultParagraphs: [String] = []
        var runningWords = 0
        var injectedCount = 0
        var subheadingIndex = 0
        
        for p in paragraphs {
            let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("##") {
                // Existing subheading resets the word counter
                runningWords = 0
                resultParagraphs.append(p)
                continue
            }
            
            let pWordCount = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            runningWords += pWordCount
            
            // If more than 280 words have elapsed without a header and current block is regular prose
            if runningWords >= 280 && !trimmed.hasPrefix("#") && !trimmed.hasPrefix(">") && !trimmed.contains("```") {
                let chosenHeader = mesoSubheadingBank[subheadingIndex % mesoSubheadingBank.count]
                subheadingIndex += 1
                resultParagraphs.append("## \(chosenHeader)")
                injectedCount += 1
                runningWords = 0
            }
            
            resultParagraphs.append(p)
        }
        
        return (resultParagraphs.joined(separator: "\n\n"), injectedCount)
    }
    
    /// Injects high-entropy pull quotes (> ...) to capture reader highlights every 320-450 words
    private static func injectPullQuotes(text: String) -> (String, Int) {
        let paragraphs = text.components(separatedBy: "\n\n")
        var result: [String] = []
        var wordsSinceLastQuote = 0
        var quoteCount = 0
        
        for p in paragraphs {
            let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
            let pWordCount = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            wordsSinceLastQuote += pWordCount
            
            result.append(p)
            
            // If over 360 words elapsed and current paragraph has a strong statement
            if wordsSinceLastQuote >= 360 && !trimmed.hasPrefix("#") && !trimmed.hasPrefix(">") && !trimmed.contains("```") {
                let sentences = extractSentences(trimmed)
                // Find a punchy sentence of 8 to 22 words
                if let bestCandidate = sentences.first(where: { s in
                    let wCount = s.components(separatedBy: .whitespaces).count
                    return wCount >= 8 && wCount <= 24 && (s.contains("because") || s.contains("trade-off") || s.contains("fails") || s.contains("cannot") || s.contains("must") || s.contains("latency") || s.contains("reality"))
                }) {
                    result.append("> \"\(bestCandidate.trimmingCharacters(in: .whitespaces))\"")
                    quoteCount += 1
                    wordsSinceLastQuote = 0
                }
            }
        }
        
        return (result.joined(separator: "\n\n"), quoteCount)
    }
    
    /// Injects micro-loop pattern interrupts to break cognitive fatigue
    private static func injectMicroInterrupts(text: String) -> (String, Int) {
        var working = text
        var count = 0
        
        for item in microInterrupts {
            if working.contains(item.pattern) {
                working = working.replacingOccurrences(of: item.pattern, with: item.replacement)
                count += 1
            }
        }
        
        return (working, count)
    }
    
    /// Appends a Boost-grade community discussion anchor
    private static func appendCommunityDiscussionAnchor(text: String) -> (String, Bool) {
        var working = text
        
        // Strip any existing bland conclusion headers
        let blandConclusionPatterns = [
            "## Conclusion", "## In Conclusion", "## Summary", "## Wrapping Up", "## Final Thoughts"
        ]
        for pattern in blandConclusionPatterns {
            working = working.replacingOccurrences(of: pattern, with: "## The Production Takeaway & Discussion")
        }
        
        // If no discussion prompt exists, append the Medium community anchor
        if !working.contains("Drop your benchmarks") && !working.contains("thoughts in the responses") {
            let communityAnchor = """
            
            ---
            
            ### The Production Takeaway & Discussion
            
            Engineering choices at scale are never free; every architectural shortcut extracts its payment at runtime.
            
            **Now over to you:** Have you encountered this bottleneck in your own production deployments, or does your operational profile behave differently under load?
            
            *Drop your benchmarks and thoughts in the responses below — I read and reply to every technical breakdown.*
            """
            working += communityAnchor
            return (working, true)
        }
        
        return (working, false)
    }
    
    // MARK: - Mathematical Helpers
    
    private static func extractSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        let pattern = #"(?<=[.!?])\s+(?=[A-Z0-9«"])"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text.components(separatedBy: ". ")
        }
        let ns = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: ns.length))
        var lastIdx = 0
        for m in matches {
            let length = m.range.location - lastIdx
            let sub = ns.substring(with: NSRange(location: lastIdx, length: length)).trimmingCharacters(in: .whitespaces)
            if !sub.isEmpty {
                sentences.append(sub)
            }
            lastIdx = m.range.location + m.range.length
        }
        if lastIdx < ns.length {
            let sub = ns.substring(with: NSRange(location: lastIdx, length: ns.length - lastIdx)).trimmingCharacters(in: .whitespaces)
            if !sub.isEmpty {
                sentences.append(sub)
            }
        }
        return sentences.isEmpty ? [text] : sentences
    }
    
    private static func computeWordCount(_ text: String) -> Int {
        let clean = TextNormalizer.markdownProse(text)
        return clean.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    /// Weibull-calibrated predicted read ratio based on word count, subheading pacing, and pull quotes
    private static func calculatePredictedReadRatio(wordCount: Int, subheadings: Int, pullQuotes: Int) -> Double {
        // Base Weibull retention drops as word count increases
        let baseRetention = exp(-pow(Double(wordCount) / 1850.0, 0.85))
        // Boost factor from scannability (subheadings every 250 words)
        let expectedSubheadings = Double(wordCount) / 280.0
        let subheadingFactor = min(1.25, 1.0 + (Double(subheadings) / max(1.0, expectedSubheadings)) * 0.15)
        // Highlight incentive factor from pull quotes
        let quoteFactor = min(1.15, 1.0 + Double(pullQuotes) * 0.03)
        
        let predicted = baseRetention * subheadingFactor * quoteFactor * 100.0
        return min(92.0, max(35.0, predicted))
    }
}
