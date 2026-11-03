import Foundation
import NaturalLanguage

public final class SlopEngine: @unchecked Sendable {
    public static let shared = SlopEngine()
    
    // Original SlopMonster Vocab Roots + Turnitout BERT/LLM Triggers
    private let vocabRoots: [String] = [
        "delve", "leverage", "seamless", "elevate", "robust", "unlock", "unleash",
        "empower", "streamline", "cutting-edge", "state-of-the-art", "game-changer",
        "game-changing", "revolutionize", "revolutionise", "transformative",
        "transformation", "innovate", "holistic", "synergy", "synergies", "paradigm", "bespoke",
        "meticulous", "tapestry", "testament", "beacon", "unparalleled", "supercharge",
        "turbocharge", "effortless", "next-level",
        "pivotal", "foster", "bolster", "showcase", "compelling", "intuitive", "world-class",
        "best-in-class", "multifaceted", "plethora"
    ]
    
    // Exact Match (words & phrases with ordinary literal senses or specific marketing/BERT tells)
    private let vocabExact: [String] = [
        "crafted", "curated", "harnessing", "harness the power", "journey", "realm", "landscape",
        "navigate the", "in the world of", "in today's", "ever-evolving", "fast-paced",
        "look no further", "dive in", "let's dive", "deep dive", "embark",
        "unlock the power", "buckle up", "the secret sauce", "level up",
        "at its core", "shed light on", "beacon of hope", "paramount importance"
    ]
    
    // Phrases & Structural tells (including Turnitout hallmark signatures)
    private let phrases: [(pattern: String, label: String, suggestion: String)] = [
        (
            #"(?:\bnot|n['’]t)\s+(?:just|only|merely|simply)\b[^.!?]{0,80}\bbut\b"#,
            "the 'not just X, but Y' construction",
            "Cut the first clause. State the actual capability or specification directly."
        ),
        (
            #"(?:\bnot|n['’]t)\s+(?:just|only|merely|simply)\b[^!?]{0,80}?[,.]\s*(?:it|this|that|they|we|you|he|she|i)\b"#,
            "the 'not just X, it's Y' construction",
            "State what it is or does without the theatrical contrast."
        ),
        (
            #"\bwhether you(?:'?re| are)\b[^.!?]{0,40}\bor\b"#,
            "the 'whether you're X or Y' opener",
            "Name the specific reader you are addressing instead of enumerating both extremes."
        ),
        (
            #"\bmore than just\b"#,
            "'more than just'",
            "Cut the phrase and describe the extra utility concretely."
        ),
        (
            #"\b(that|this)(?:'?s| is) where\b[^.!?]{0,30}\bcomes? in\b"#,
            "'that's where X comes in'",
            "State what the tool or step actually accomplishes."
        ),
        (
            #"\bsay goodbye to\b"#,
            "'say goodbye to'",
            "Name what replaces it or the specific manual step eliminated."
        ),
        (
            #"\bimagine (a|an|the)\b"#,
            "the 'imagine a…' opener",
            "Show the concrete benefit or workflow instead of prompting the reader's imagination."
        ),
        (
            #"\bin conclusion\b|\bto sum up\b"#,
            "essay-summary phrasing",
            "Omit or transition directly to the next actionable step."
        ),
        (
            #"\bwhen it comes to\b"#,
            "'when it comes to' filler",
            "Delete or replace with 'for' or 'with'."
        ),
        (
            #"\bat the end of the day\b"#,
            "'at the end of the day'",
            "Cut this clichéd conversational filler."
        ),
        (
            #"\bthe key is\b|\bthe truth is\b"#,
            "throat-clearing opener",
            "State the point without the preamble."
        ),
        (
            #"\bhelps? you to\b|\bcan help you\b"#,
            "hedged benefit ('helps you to…')",
            "Use direct action verbs: 'runs', 'builds', 'prevents'."
        ),
        (
            #"\bmay potentially\b|\bcould potentially\b|\bmight possibly\b"#,
            "stacked hedging",
            "Use a single verb expressing the author's real degree of certainty."
        ),
        (
            #"\bvery unique\b|\bquite literally\b"#,
            "intensifier padding",
            "Cut the intensifier."
        ),
        (
            #"\bhere'?s the thing\b|\blet'?s break (it|this) down\b|\bthe best part\b"#,
            "throat-clearing opener",
            "Get straight to the explanation."
        ),
        (
            #"\bready to get started\b|\blet'?s get started\b"#,
            "boilerplate CTA",
            "Provide the first command or next specific step."
        ),
        (
            #"\bthe (result|answer|catch|kicker|upshot)\?\s"#,
            "self-answering question",
            "Merge into a declarative sentence."
        ),
        // Turnitout Specific AI Signatures & BERT Patterns
        (
            #"\b(?:it is (?:important|crucial|essential) to )?delve (?:deep )?into\b"#,
            "BERT hallmark trigger: 'delve into'",
            "Replace with direct verbs like 'examine', 'explore', 'study', or 'analyze'."
        ),
        (
            #"\b(?:comprehensive|rich|intricate)\s+tapestry(?:\s+of)?\b"#,
            "metaphorical cliché: 'tapestry of'",
            "Replace with concrete descriptions: 'range of', 'network of', or 'system'."
        ),
        (
            #"\b(?:stands?|serves?)\s+as\s+a\s+testament\s+to\b"#,
            "formulaic cliché: 'testament to'",
            "Replace with 'reflects', 'demonstrates', or 'proves'."
        ),
        (
            #"\bplays?\s+a\s+(?:pivotal|crucial|vital|key)\s+role\s+in(?:\s+illustrating)?\b"#,
            "overused pattern: 'plays a pivotal role'",
            "Replace with 'is essential to', 'enables', or 'drives'."
        ),
        (
            #"\b(?:the\s+)?interplay\s+between\b"#,
            "academic cliché: 'interplay between'",
            "Replace with 'relationship between', 'interaction of', or 'balance of'."
        ),
        (
            #"\bprovides?\s+a\s+robust\s+framework\b"#,
            "formulaic pattern: 'provides a robust framework'",
            "Replace with 'offers a solid basis', 'supports', or 'establishes'."
        ),
        (
            #"\b(?:in\s+today's\s+)?fast-paced\s+digital\s+(?:era|world|landscape)\b"#,
            "throat-clearing opener: 'fast-paced digital era'",
            "Replace with 'today', 'currently', or state the specific timeline."
        ),
        (
            #"\bserves?\s+as\s+a\s+critical\s+milestone\b"#,
            "cliché: 'critical milestone'",
            "Replace with 'marks a major turning point' or describe the event directly."
        ),
        (
            #"\bcannot\s+be\s+overlooked\b"#,
            "passive filler: 'cannot be overlooked'",
            "Replace with active statement: 'we must address' or 'deserves attention'."
        ),
        (
            #"\bdelve\s+deep\s+into\s+the\s+multifaceted\s+dimensions\s+of\b"#,
            "verbose AI construction: 'multifaceted dimensions of'",
            "Replace with 'examine the details of' or 'study'."
        ),
        (
            #"\b(?:it\s+is\s+of\s+)?paramount\s+importance\b"#,
            "puffed-up formal filler: 'paramount importance'",
            "Replace with 'critical', 'essential', or 'crucial'."
        )
    ]
    
    // Precompiled regex caches
    private var precompiledVocab: [(word: String, regex: NSRegularExpression)] = []
    private var precompiledExact: [(word: String, regex: NSRegularExpression)] = []
    private var precompiledPhrases: [(label: String, suggestion: String, regex: NSRegularExpression)] = []
    private var compoundRegex: NSRegularExpression?
    private var proofRegex: NSRegularExpression?
    private var tricolonRegexes: [NSRegularExpression] = []
    
    private init() {
        // Build regexes once
        for w in vocabRoots {
            let root = (try? NSRegularExpression(pattern: #"(ed|ing|ly|e)$"#, options: []))?
                .stringByReplacingMatches(in: w, options: [], range: NSRange(location: 0, length: w.utf16.count), withTemplate: "") ?? w
            let pat = root.count < 4 ? "(?<!\\w)\(NSRegularExpression.escapedPattern(for: w))(?!\\w)" :
                "(?<!\\w)\(NSRegularExpression.escapedPattern(for: root))(?:e|es|ed|ing|ion|ions|ional|ive|al|ally|s|ly|ness)?(?!\\w)"
            if let r = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) {
                precompiledVocab.append((w, r))
            }
        }
        
        for w in vocabExact {
            let pat = "(?<!\\w)\(NSRegularExpression.escapedPattern(for: w))(?!\\w)"
            if let r = try? NSRegularExpression(pattern: pat, options: [.caseInsensitive]) {
                precompiledExact.append((w, r))
            }
        }
        
        for p in phrases {
            if let r = try? NSRegularExpression(pattern: p.pattern, options: [.caseInsensitive]) {
                precompiledPhrases.append((p.label, p.suggestion, r))
            }
        }
        
        compoundRegex = try? NSRegularExpression(pattern: #"\b[a-z]{2,}-[a-z]{2,}(?:-[a-z]{2,})*\b"#, options: [.caseInsensitive])
        
        let proofPat = #"([\d][\d,]*(?:\.\d+)?)\s*\+?\s*((?:happy|early|active|satisfied|verified|trusted|delighted)\s+)?(?:\w+\s+){0,1}(users?|customers?|learners?|students?|teams?|members?|companies|businesses|homeowners?|subscribers?|clients?|patients?|readers?|sites?|projects?)(?!\w)"#
        proofRegex = try? NSRegularExpression(pattern: proofPat, options: [.caseInsensitive])
        
        let tri1 = #"\b(\w{4,}),\s+(\w{4,}),\s+and\s+(\w{4,})\b"#
        let tri2 = #"\b(\w{4,}),\s+(\w{4,})\s+and\s+((?:\w+\s+){1,2}\w+)\s*[.!?,;:]"#
        if let r1 = try? NSRegularExpression(pattern: tri1, options: [.caseInsensitive]),
           let r2 = try? NSRegularExpression(pattern: tri2, options: [.caseInsensitive]) {
            tricolonRegexes = [r1, r2]
        }
    }
    
    public func audit(text: String, isMarkdown: Bool = true, allowProof: Bool = false, authorProfile: AuthorProfile? = nil) -> SlopReport {
        // Step 0: Scan for hidden Zero-Width Unicode characters in raw input
        let watermarkCount = TextNormalizer.countZeroWidthUnicode(text)
        var hits: [SlopHit] = []
        
        if watermarkCount > 0 {
            hits.append(SlopHit(
                category: .watermark,
                label: "covert zero-width tracking characters (\(watermarkCount) detected)",
                snippet: "\(watermarkCount) hidden Unicode watermarks (U+200B/C/D/2060/FEFF)",
                range: NSRange(location: 0, length: min(30, (text as NSString).length)),
                lineNumber: 1,
                suggestion: "Purge covert Unicode watermarks before submitting or running compilers."
            ))
        }
        
        let rawNormalized = TextNormalizer.normalise(text)
        guard !rawNormalized.isEmpty else {
            return SlopReport.empty
        }
        
        let prose = isMarkdown ? TextNormalizer.markdownProse(text) : TextNormalizer.htmlProse(text)
        let words = prose.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordCount = words.count
        let charCount = prose.count
        
        let nsProse = prose as NSString
        let fullRange = NSRange(location: 0, length: nsProse.length)
        
        // Helper to find line numbers
        func line(at loc: Int) -> Int {
            var count = 1
            let sub = nsProse.substring(to: min(loc, nsProse.length))
            for ch in sub where ch == "\n" {
                count += 1
            }
            return count
        }
        
        // 1. AI Vocabulary (Roots)
        for item in precompiledVocab {
            let matches = item.regex.matches(in: prose, options: [], range: fullRange)
            for m in matches {
                let snip = nsProse.substring(with: m.range)
                hits.append(SlopHit(
                    category: .vocab,
                    label: "overused term: '\(item.word)'",
                    snippet: snip,
                    range: m.range,
                    lineNumber: line(at: m.range.location),
                    suggestion: "Replace with simpler, concrete phrasing (e.g., 'use', 'create', 'show')."
                ))
            }
        }
        
        // 2. AI Vocabulary (Exact)
        for item in precompiledExact {
            let matches = item.regex.matches(in: prose, options: [], range: fullRange)
            for m in matches {
                let snip = nsProse.substring(with: m.range)
                hits.append(SlopHit(
                    category: .vocab,
                    label: "marketing tell: '\(item.word)'",
                    snippet: snip,
                    range: m.range,
                    lineNumber: line(at: m.range.location),
                    suggestion: "Remove metaphorical fluff; describe the actual action."
                ))
            }
        }
        
        // 3. AI Sentence Constructions
        for item in precompiledPhrases {
            let matches = item.regex.matches(in: prose, options: [], range: fullRange)
            for m in matches {
                let snip = nsProse.substring(with: m.range)
                hits.append(SlopHit(
                    category: .phrases,
                    label: item.label,
                    snippet: snip,
                    range: m.range,
                    lineNumber: line(at: m.range.location),
                    suggestion: item.suggestion
                ))
            }
        }
        
        // 4. Punctuation Cadence (Em-dashes & compounds in 220-char windows)
        let sentences = prose.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
        var searchPos = 0
        for s in sentences where !s.isEmpty {
            let sLen = s.utf16.count
            var i = 0
            while i < max(1, sLen) {
                let windowLen = min(220, sLen - i)
                let window = (s as NSString).substring(with: NSRange(location: i, length: windowLen))
                
                // Em-dash count
                let dashCount = window.filter { $0 == "—" }.count
                if dashCount >= 2 {
                    let hitRange = NSRange(location: min(searchPos + i, nsProse.length), length: min(windowLen, nsProse.length - searchPos - i))
                    hits.append(SlopHit(
                        category: .punctuation,
                        label: "two or more em-dashes in one sentence window",
                        snippet: window.prefix(70).trimmingCharacters(in: .whitespacesAndNewlines),
                        range: hitRange,
                        lineNumber: line(at: hitRange.location),
                        suggestion: "Break into two clear sentences or use standard commas."
                    ))
                    break
                }
                
                // Hyphenated compound stacking (>= 4)
                if let compMatches = compoundRegex?.matches(in: window, options: [], range: NSRange(location: 0, length: window.utf16.count)), compMatches.count >= 4 {
                    let hitRange = NSRange(location: min(searchPos + i, nsProse.length), length: min(windowLen, nsProse.length - searchPos - i))
                    let compSnippet = compMatches.prefix(4).map { (window as NSString).substring(with: $0.range) }.joined(separator: ", ")
                    hits.append(SlopHit(
                        category: .punctuation,
                        label: "\(compMatches.count) hyphenated compounds stacked in one sentence",
                        snippet: compSnippet,
                        range: hitRange,
                        lineNumber: line(at: hitRange.location),
                        suggestion: "Unpack buzzword compounds into concrete technical specifications."
                    ))
                    break
                }
                i += 220
            }
            searchPos += sLen + 1
        }
        
        // Semicolon density check
        let semiCount = prose.filter { $0 == ";" }.count
        if semiCount > max(3, wordCount / 200) {
            hits.append(SlopHit(
                category: .punctuation,
                label: "semicolon-heavy for web copy (\(semiCount) found)",
                snippet: "\(semiCount) semicolons across \(wordCount) words",
                range: NSRange(location: 0, length: min(10, nsProse.length)),
                lineNumber: 1,
                suggestion: "Replace semicolons with clean full stops or bullet points."
            ))
        }
        
        // 5. Rhythm (Rule of Three lists)
        for tri in tricolonRegexes {
            let matches = tri.matches(in: prose, options: [], range: fullRange)
            for m in matches {
                let snip = nsProse.substring(with: m.range)
                hits.append(SlopHit(
                    category: .rhythm,
                    label: "rule-of-three rhetorical list",
                    snippet: snip.prefix(60).trimmingCharacters(in: .whitespacesAndNewlines),
                    range: m.range,
                    lineNumber: line(at: m.range.location),
                    suggestion: "Replace three rhetorical adjectives with one solid fact or specification."
                ))
            }
        }
        
        // 6. Unsupported Proof
        if let pMatches = proofRegex?.matches(in: prose, options: [], range: fullRange) {
            for m in pMatches {
                let snip = nsProse.substring(with: m.range)
                hits.append(SlopHit(
                    category: .proof,
                    label: "possible unverified social proof metric",
                    snippet: snip.trimmingCharacters(in: .whitespacesAndNewlines),
                    range: m.range,
                    lineNumber: line(at: m.range.location),
                    suggestion: "Verify proof with receipts/dates, or clearly state that it is a sample."
                ))
            }
        }
        
        // 7. NaturalLanguage Cadence & Burstiness Analysis
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = prose
        var sentenceLengths: [Double] = []
        var totalSentenceCount = 0
        
        tokenizer.enumerateTokens(in: prose.startIndex..<prose.endIndex) { range, _ in
            let sent = String(prose[range])
            let sWords = sent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            if !sWords.isEmpty {
                sentenceLengths.append(Double(sWords.count))
                totalSentenceCount += 1
            }
            return true
        }
        
        var stdDev = 0.0
        var avgLength = 0.0
        var coeffVar = 0.0
        if !sentenceLengths.isEmpty {
            avgLength = sentenceLengths.reduce(0, +) / Double(sentenceLengths.count)
            let sumSq = sentenceLengths.reduce(0) { $0 + pow($1 - avgLength, 2) }
            stdDev = sqrt(sumSq / Double(sentenceLengths.count))
            coeffVar = avgLength > 0 ? (stdDev / avgLength) : 0.0
            
            // Standard sentence metronome detection
            if sentenceLengths.count >= 5 && coeffVar < 0.24 && avgLength > 12 {
                hits.append(SlopHit(
                    category: .burstiness,
                    label: "robotic sentence metronome (uniform length CV: \(String(format: "%.2f", coeffVar)))",
                    snippet: "Avg: \(Int(avgLength)) words/sentence, SD: \(String(format: "%.1f", stdDev))",
                    range: NSRange(location: 0, length: min(30, nsProse.length)),
                    lineNumber: 1,
                    suggestion: "Vary cadence: introduce short punchy sentences (3-5 words) amidst longer clauses."
                ))
            } else if wordCount >= 600 && coeffVar < 0.32 {
                // Theorem: Over long documents (>600 words), low variance reliably separates AI from humans
                hits.append(SlopHit(
                    category: .burstiness,
                    label: "macro-cadence monotony across long article (CV: \(String(format: "%.2f", coeffVar)))",
                    snippet: "Sentence length variance too narrow across \(wordCount) words",
                    range: NSRange(location: 0, length: min(30, nsProse.length)),
                    lineNumber: 1,
                    suggestion: "Long articles require asymmetric rhythm (Staccato-Legato Law): mix 3-word sentences with 40-word complex clauses."
                ))
            }
        }
        
        // 8. Long-Document Macro Paragraph Asymmetry Audit (Central Limit Theorem Defense)
        let rawParas = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).count >= 8 }
        let paraCount = max(1, rawParas.count)
        var paraWordCounts: [Double] = []
        for p in rawParas {
            let pWords = p.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            paraWordCounts.append(Double(pWords.count))
        }
        
        var paraStdDev = 0.0
        if paraWordCounts.count >= 3 {
            let pAvg = paraWordCounts.reduce(0, +) / Double(paraWordCounts.count)
            let pSumSq = paraWordCounts.reduce(0) { $0 + pow($1 - pAvg, 2) }
            paraStdDev = sqrt(pSumSq / Double(paraWordCounts.count))
            
            // If article is >500 words and paragraphs are uniformly cookie-cutter (SD < 15 words)
            if wordCount >= 500 && paraStdDev < 15.0 && pAvg >= 40.0 {
                hits.append(SlopHit(
                    category: .burstiness,
                    label: "uniform paragraph stacking across long article (para SD: \(String(format: "%.1f", paraStdDev)) words)",
                    snippet: "All \(paraCount) paragraphs are uniformly ~\(Int(pAvg)) words",
                    range: NSRange(location: 0, length: min(30, nsProse.length)),
                    lineNumber: 1,
                    suggestion: "Break formulaic paragraph lengths: insert a 1-sentence punchy thesis paragraph, or expand a deep technical section."
                ))
            }
            
            // Check repetitive macro-discourse openers across paragraphs
            var prevOpener = ""
            for (idx, p) in rawParas.enumerated() {
                let firstWord = p.components(separatedBy: .whitespacesAndNewlines).first?.lowercased().trimmingCharacters(in: .punctuationCharacters) ?? ""
                let transitionSet: Set<String> = ["moreover", "furthermore", "additionally", "consequently", "therefore", "however", "similarly", "importantly"]
                if transitionSet.contains(firstWord) {
                    if firstWord == prevOpener {
                        hits.append(SlopHit(
                            category: .phrases,
                            label: "repetitive paragraph opening transition '\(firstWord)'",
                            snippet: "Paragraphs \(idx) and \(idx + 1) both begin with '\(firstWord)'",
                            range: NSRange(location: 0, length: min(30, nsProse.length)),
                            lineNumber: max(1, idx * 3),
                            suggestion: "Rotate discourse markers or start paragraphs directly with the subject noun phrase."
                        ))
                    }
                    prevOpener = firstWord
                } else {
                    prevOpener = ""
                }
            }
        }
        
        // 9. Turnitout ZipPy Compression Perplexity Audit
        let entropyRes = ZipPyAnalyzer.evaluate(text: prose)
        if wordCount >= 50 && entropyRes.entropyPercentage < 42.0 {
            hits.append(SlopHit(
                category: .burstiness,
                label: "low entropic perplexity (\(String(format: "%.1f", entropyRes.entropyPercentage))% human score)",
                snippet: "ZLIB ratio \(String(format: "%.2f", entropyRes.compressionRatio)) indicates formulaic token repetition",
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Disrupt contiguous n-gram sequences: rotate synonyms, vary discourse markers, or reorder clauses."
            ))
        }
        
        // 10. Tier-3 Mathematical Frontier: Zipfian Power-Law & Yngve Syntactic Depth Audits
        let zipfMetrics = ZipfianAnalyzer.evaluate(text: prose)
        if wordCount >= 70 && !zipfMetrics.isZipfianCompliant && zipfMetrics.hapaxLegomenaRatio < 0.35 {
            hits.append(SlopHit(
                category: .vocab,
                label: "lexical 'fat middle' (hapax ratio: \(Int(zipfMetrics.hapaxLegomenaRatio * 100))%)",
                snippet: zipfMetrics.assessment,
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Restore natural Zipfian power law: replace overused mid-tier vocabulary with rare long-tail terms."
            ))
        }
        
        let syntaxMetrics = SyntaxTreeAnalyzer.evaluate(text: prose)
        if wordCount >= 90 && !syntaxMetrics.isSyntacticallyDiverse {
            hits.append(SlopHit(
                category: .burstiness,
                label: "uniform syntactic tree depth (tree SD: \(String(format: "%.2f", syntaxMetrics.depthVariance)))",
                snippet: syntaxMetrics.assessment,
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Vary dependency tree depths: alternate flat statements with deep recursive clauses."
            ))
        }
        
        // 11. Frontier 5: Hurst Exponent — Long-Range Dependence in Sentence Rhythm
        let hurstMetrics = HurstExponentAnalyzer.evaluate(text: prose)
        if wordCount >= 200 && !hurstMetrics.hasLongRangeMemory {
            hits.append(SlopHit(
                category: .burstiness,
                label: "random walk cadence (Hurst H = \(String(format: "%.3f", hurstMetrics.hurstExponent)))",
                snippet: hurstMetrics.assessment,
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Build narrative rhythm arcs: cluster short sentences together, then expand into longer explanatory passages."
            ))
        }
        
        // 12. Frontier 6: Burstiness / Fano Factor — Word Reuse Clustering
        let burstMetrics = BurstinessAnalyzer.evaluate(text: prose)
        if wordCount >= 120 && !burstMetrics.isBursty {
            hits.append(SlopHit(
                category: .burstiness,
                label: "Poisson word spacing (Fano F = \(String(format: "%.2f", burstMetrics.fanoFactor)))",
                snippet: burstMetrics.assessment,
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Reuse key content words in topical bursts (clusters) rather than spreading them uniformly."
            ))
        }
        
        // 13. Frontier 7: Benford's Law — Leading Digit Distribution of Word Frequencies
        let benfordMetrics = BenfordAnalyzer.evaluate(text: prose)
        if wordCount >= 100 && !benfordMetrics.isBenfordCompliant {
            hits.append(SlopHit(
                category: .vocab,
                label: "Benford's Law violation (χ² = \(String(format: "%.1f", benfordMetrics.chiSquaredStatistic)))",
                snippet: benfordMetrics.assessment,
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Diversify word frequencies across orders of magnitude: use some words once, others 2-3 times, and key terms 5+ times."
            ))
        }
        
        // 14. Frontier 8: Heaps' Law — Vocabulary Growth Rate
        let heapsMetrics = HeapsLawAnalyzer.evaluate(text: prose)
        if wordCount >= 100 && !heapsMetrics.isHeapsCompliant {
            hits.append(SlopHit(
                category: .vocab,
                label: "vocabulary saturation (Heaps β = \(String(format: "%.3f", heapsMetrics.heapsBeta)))",
                snippet: heapsMetrics.assessment,
                range: NSRange(location: 0, length: min(30, nsProse.length)),
                lineNumber: 1,
                suggestion: "Introduce new vocabulary progressively throughout the document; avoid recycling the same word pool."
            ))
        }
        
        // 15. Frontier 4: Author KL-Divergence Stylometric Matching
        let stylometricMatch: StylometricMatchReport
        if let profile = authorProfile, wordCount >= 50 {
            stylometricMatch = AuthorProfileEngine.matchAgainstProfile(text: prose, profile: profile)
        } else {
            stylometricMatch = .empty
        }
        
        // Calculate Classical Score (0-5)
        var failedCats = Set(hits.map { $0.category })
        if allowProof {
            failedCats.remove(.proof)
        }
        // Burstiness and Watermark are advisory/safety categories; they don't break the original 5 classic gates
        failedCats.remove(.burstiness)
        failedCats.remove(.watermark)
        
        let classicScore = max(0, 5 - failedCats.count)
        let sdi = wordCount > 0 ? (Double(hits.count) / Double(wordCount)) * 100.0 : 0.0
        let readingTime = max(1, (wordCount * 60) / 220)
        
        // Compute Macro-Resilience Score (0-100%)
        var resilience = 100.0
        resilience -= Double(5 - classicScore) * 8.0
        if entropyRes.entropyPercentage < 50.0 {
            resilience -= (50.0 - entropyRes.entropyPercentage) * 0.8
        }
        if wordCount >= 500 && coeffVar < 0.32 {
            resilience -= 12.0
        }
        if wordCount >= 500 && paraStdDev < 15.0 && paraCount >= 4 {
            resilience -= 12.0
        }
        if !zipfMetrics.isZipfianCompliant && wordCount >= 70 {
            resilience -= 8.0
        }
        if !syntaxMetrics.isSyntacticallyDiverse && wordCount >= 90 {
            resilience -= 8.0
        }
        if !hurstMetrics.hasLongRangeMemory && wordCount >= 200 {
            resilience -= 6.0
        }
        if !burstMetrics.isBursty && wordCount >= 120 {
            resilience -= 6.0
        }
        if !benfordMetrics.isBenfordCompliant && wordCount >= 100 {
            resilience -= 5.0
        }
        if !heapsMetrics.isHeapsCompliant && wordCount >= 100 {
            resilience -= 5.0
        }
        if authorProfile != nil && stylometricMatch.matchPercentage < 70.0 {
            resilience -= (70.0 - stylometricMatch.matchPercentage) * 0.2
        }
        if watermarkCount > 0 {
            resilience -= min(25.0, Double(watermarkCount) * 5.0)
        }
        let finalResilience = max(10.0, min(99.0, resilience))
        
        return SlopReport(
            hits: hits,
            wordCount: wordCount,
            characterCount: charCount,
            sentenceCount: max(1, totalSentenceCount),
            classicScore: classicScore,
            slopDensityIndex: sdi,
            isClean: classicScore == 5 && hits.filter({ $0.category != .proof || !allowProof }).isEmpty,
            sentenceLengthVariance: stdDev,
            averageSentenceLength: avgLength,
            estimatedReadingTimeSeconds: readingTime,
            watermarkCount: watermarkCount,
            entropyResult: entropyRes,
            paragraphCount: paraCount,
            paragraphLengthVariance: paraStdDev,
            macroResilienceScore: finalResilience,
            zipfianMetrics: zipfMetrics,
            syntaxMetrics: syntaxMetrics,
            hurstMetrics: hurstMetrics,
            burstinessMetrics: burstMetrics,
            benfordMetrics: benfordMetrics,
            heapsMetrics: heapsMetrics,
            stylometricMatch: stylometricMatch
        )
    }
}
