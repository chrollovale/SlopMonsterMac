import Foundation

public struct DeterministicHumanizeResult: Sendable {
    public let transformedText: String
    public let editsApplied: [String]
    public let purgedWatermarks: Int
    public let wordCountDelta: Int
    
    public init(transformedText: String, editsApplied: [String], purgedWatermarks: Int, wordCountDelta: Int) {
        self.transformedText = transformedText
        self.editsApplied = editsApplied
        self.purgedWatermarks = purgedWatermarks
        self.wordCountDelta = wordCountDelta
    }
}

public enum DeterministicHumanizer {
    
    // Multi-word phrase rewrites (ordered by specificity)
    private static let phraseRules: [(pattern: String, replacement: String, label: String)] = [
        (#"(?i)\bIn conclusion, it is important to delve into\b"#, "To wrap up, we examine", "Replaced 'In conclusion, it is important to delve into'"),
        (#"(?i)\bit is important to delve into\b"#, "we examine", "Replaced 'it is important to delve into'"),
        (#"(?i)\bdelve deep into the multifaceted dimensions of\b"#, "examine the details of", "Replaced 'delve deep into multifaceted dimensions'"),
        (#"(?i)\bdelve deep into\b"#, "examine", "Replaced 'delve deep into'"),
        (#"(?i)\bdelve into\b"#, "examine", "Replaced 'delve into'"),
        (#"(?i)\bcomprehensive tapestry of\b"#, "broad range of", "Replaced 'comprehensive tapestry of'"),
        (#"(?i)\bcomprehensive tapestry\b"#, "broad range", "Replaced 'comprehensive tapestry'"),
        (#"(?i)\brich tapestry of\b"#, "diverse collection of", "Replaced 'rich tapestry of'"),
        (#"(?i)\bplays a pivotal role in illustrating\b"#, "clearly demonstrates", "Replaced 'plays a pivotal role in illustrating'"),
        (#"(?i)\bplays a pivotal role\b"#, "is essential", "Replaced 'plays a pivotal role'"),
        (#"(?i)\bplay a pivotal role\b"#, "are essential", "Replaced 'play a pivotal role'"),
        (#"(?i)\bstands as a testament to\b"#, "reflects", "Replaced 'stands as a testament to'"),
        (#"(?i)\bstand as a testament to\b"#, "reflect", "Replaced 'stand as a testament to'"),
        (#"(?i)\bserves as a testament to\b"#, "demonstrates", "Replaced 'serves as a testament to'"),
        (#"(?i)\bserve as a testament to\b"#, "demonstrate", "Replaced 'serve as a testament to'"),
        (#"(?i)\bFurthermore, the interplay between\b"#, "Also, balancing", "Replaced 'Furthermore, the interplay between'"),
        (#"(?i)\bthe interplay between\b"#, "the relationship between", "Replaced 'the interplay between'"),
        (#"(?i)\binterplay between\b"#, "relationship between", "Replaced 'interplay between'"),
        (#"(?i)\bprovides a robust framework\b"#, "gives a solid basis", "Replaced 'provides a robust framework'"),
        (#"(?i)\bprovide a robust framework\b"#, "give a solid basis", "Replaced 'provide a robust framework'"),
        (#"(?i)\bMoreover, in today's fast-paced digital era,?\b"#, "Today,", "Replaced 'in today's fast-paced digital era'"),
        (#"(?i)\bin today's fast-paced digital era,?\b"#, "today,", "Replaced 'in today's fast-paced digital era'"),
        (#"(?i)\bin today's fast-paced world,?\b"#, "today,", "Replaced 'in today's fast-paced world'"),
        (#"(?i)\bserves as a critical milestone\b"#, "is a major turning point", "Replaced 'serves as a critical milestone'"),
        (#"(?i)\bcannot be overlooked\b"#, "we must address", "Replaced 'cannot be overlooked'"),
        (#"(?i)\bit is of paramount importance\b"#, "it is essential", "Replaced 'it is of paramount importance'"),
        (#"(?i)\bparamount importance\b"#, "essential", "Replaced 'paramount importance'"),
        (#"(?i)\bat the end of the day\b"#, "ultimately", "Replaced 'at the end of the day'"),
        (#"(?i)\bwhen it comes to\b"#, "for", "Replaced 'when it comes to'"),
        (#"(?i)\bsay goodbye to\b"#, "eliminate", "Replaced 'say goodbye to'"),
        (#"(?i)\bthat's where Ridgeline comes in\b"#, "Ridgeline addresses this", "Replaced 'that's where X comes in'"),
        (#"(?i)\bthat is where ([a-zA-Z0-9_-]+) comes in\b"#, "$1 addresses this", "Replaced 'that is where X comes in'"),
        (#"(?i)\bthat's where ([a-zA-Z0-9_-]+) comes in\b"#, "$1 addresses this", "Replaced 'that's where X comes in'"),
        (#"(?i)\bIt is not just a ([^,]+), it is a ([^.]+)\b"#, "Beyond a $1, it provides a $2", "Replaced negated-just construction"),
        (#"(?i)\bIt's not just a ([^,]+), it's a ([^.]+)\b"#, "Beyond a $1, it provides a $2", "Replaced negated-just construction"),
        (#"(?i)\bIn conclusion,?\b"#, "To wrap up,", "Replaced 'In conclusion'"),
        (#"(?i)\bTo sum up,?\b"#, "In summary,", "Replaced 'To sum up'")
    ]
    
    // 1-to-1 Single-Word Synonym Swaps (Exact 1:1 token replacement - Zero Expansion)
    private static let oneToOneSynonyms: [(pattern: String, replacement: String, label: String)] = [
        (#"(?i)\bcutting-edge\b"#, "advanced", "cutting-edge → advanced"),
        (#"(?i)\bstate-of-the-art\b"#, "modern", "state-of-the-art → modern"),
        (#"(?i)\bseamlessly\b"#, "smoothly", "seamlessly → smoothly"),
        (#"(?i)\bseamless\b"#, "direct", "seamless → direct"),
        (#"(?i)\belevating\b"#, "improving", "elevating → improving"),
        (#"(?i)\belevates\b"#, "improves", "elevates → improves"),
        (#"(?i)\belevate\b"#, "improve", "elevate → improve"),
        (#"(?i)\bleveraging\b"#, "using", "leveraging → using"),
        (#"(?i)\bleverages\b"#, "uses", "leverages → uses"),
        (#"(?i)\bleverage\b"#, "use", "leverage → use"),
        (#"(?i)\brobust\b"#, "solid", "robust → solid"),
        (#"(?i)\bunleashing\b"#, "enabling", "unleashing → enabling"),
        (#"(?i)\bunleashes\b"#, "enables", "unleashes → enables"),
        (#"(?i)\bunleash\b"#, "enable", "unleash → enable"),
        (#"(?i)\bempowering\b"#, "equipping", "empowering → equipping"),
        (#"(?i)\bempowers\b"#, "equips", "empowers → equips"),
        (#"(?i)\bempower\b"#, "equip", "empower → equip"),
        (#"(?i)\bstreamlining\b"#, "simplifying", "streamlining → simplifying"),
        (#"(?i)\bstreamlines\b"#, "simplifies", "streamlines → simplifies"),
        (#"(?i)\bstreamline\b"#, "simplify", "streamline → simplify"),
        (#"(?i)\bgame-changing\b"#, "significant", "game-changing → significant"),
        (#"(?i)\bgame-changer\b"#, "breakthrough", "game-changer → breakthrough"),
        (#"(?i)\btransformative\b"#, "meaningful", "transformative → meaningful"),
        (#"(?i)\btransformation\b"#, "change", "transformation → change"),
        (#"(?i)\bholistic\b"#, "thorough", "holistic → thorough"),
        (#"(?i)\bsynergy\b"#, "cohesion", "synergy → cohesion"),
        (#"(?i)\bsynergies\b"#, "cooperation", "synergies → cooperation"),
        (#"(?i)\bnext-level\b"#, "advanced", "next-level → advanced"),
        (#"(?i)\bpivotal\b"#, "key", "pivotal → key"),
        (#"(?i)\bfostering\b"#, "promoting", "fostering → promoting"),
        (#"(?i)\bfosters\b"#, "promotes", "fosters → promotes"),
        (#"(?i)\bfoster\b"#, "promote", "foster → promote"),
        (#"(?i)\bbolstering\b"#, "strengthening", "bolstering → strengthening"),
        (#"(?i)\bbolsters\b"#, "strengthens", "bolsters → strengthens"),
        (#"(?i)\bbolster\b"#, "strengthen", "bolster → strengthen"),
        (#"(?i)\bmultifaceted\b"#, "varied", "multifaceted → varied"),
        (#"(?i)\bparadigm\b"#, "model", "paradigm → model"),
        (#"(?i)\bmeticulous\b"#, "thorough", "meticulous → thorough"),
        (#"(?i)\bmeticulously\b"#, "thoroughly", "meticulously → thoroughly")
    ]
    
    // Discourse marker rotation dictionaries
    private static let discourseRotations: [String: [String]] = [
        "However": ["Nevertheless", "Nonetheless", "On the other hand", "That said"],
        "Therefore": ["Consequently", "Hence", "Accordingly", "As a result"],
        "Moreover": ["Furthermore", "In addition", "Additionally", "Beyond this"],
        "Furthermore": ["In addition", "Moreover", "Additionally"],
        "Thus": ["Hence", "Accordingly", "As such"]
    ]
    
    // Contraction transformations for author voice matching
    private static let unrollContractions: [(pattern: String, replacement: String)] = [
        (#"(?i)\bdon't\b"#, "do not"),
        (#"(?i)\bdoesn't\b"#, "does not"),
        (#"(?i)\bdidn't\b"#, "did not"),
        (#"(?i)\bwon't\b"#, "will not"),
        (#"(?i)\bwouldn't\b"#, "would not"),
        (#"(?i)\bcouldn't\b"#, "could not"),
        (#"(?i)\bshouldn't\b"#, "should not"),
        (#"(?i)\bcan't\b"#, "cannot"),
        (#"(?i)\bisn't\b"#, "is not"),
        (#"(?i)\baren't\b"#, "are not"),
        (#"(?i)\bit's\b"#, "it is"),
        (#"(?i)\bthat's\b"#, "that is"),
        (#"(?i)\bthere's\b"#, "there is"),
        (#"(?i)\bwe're\b"#, "we are"),
        (#"(?i)\bthey're\b"#, "they are"),
        (#"(?i)\byou're\b"#, "you are")
    ]
    
    private static let rollContractions: [(pattern: String, replacement: String)] = [
        (#"(?i)\bdo not\b"#, "don't"),
        (#"(?i)\bdoes not\b"#, "doesn't"),
        (#"(?i)\bdid not\b"#, "didn't"),
        (#"(?i)\bwill not\b"#, "won't"),
        (#"(?i)\bcannot\b"#, "can't"),
        (#"(?i)\bit is\b"#, "it's"),
        (#"(?i)\bthat is\b"#, "that's"),
        (#"(?i)\bthere is\b"#, "there's"),
        (#"(?i)\bwe are\b"#, "we're"),
        (#"(?i)\bthey are\b"#, "they're"),
        (#"(?i)\byou are\b"#, "you're")
    ]
    
    /// Deterministically transforms prose without any external LLM calls (Turnitout Zero-AI Mode)
    public static func humanize(
        text: String,
        zeroExpansion: Bool = false,
        adversarialSpikes: Bool = false,
        authorProfile: AuthorProfile? = nil
    ) -> DeterministicHumanizeResult {
        var edits: [String] = []
        
        // 1. Purge Zero-Width Unicode characters
        let (purgedText, watermarkCount) = TextNormalizer.purgeZeroWidthUnicode(text)
        if watermarkCount > 0 {
            edits.append("Purged \(watermarkCount) invisible zero-width Unicode tracking characters (EU AI Act)")
        }
        
        // 2. Protect LaTeX Math, Code Blocks, and Citations
        let (maskedText, placeholders) = TextNormalizer.maskProtectedZones(purgedText)
        var working = maskedText
        
        // 3. Apply Multi-Word Phrase Rewrites
        for rule in phraseRules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: []) {
                let matches = regex.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
                if !matches.isEmpty {
                    working = regex.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: rule.replacement)
                    edits.append(rule.label)
                }
            }
        }
        
        // 4. Apply 1:1 Contextual Synonym Swaps (Exact token parity)
        for syn in oneToOneSynonyms {
            if let regex = try? NSRegularExpression(pattern: syn.pattern, options: []) {
                let matches = regex.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
                if !matches.isEmpty {
                    working = regex.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: syn.replacement)
                    edits.append(syn.label)
                }
            }
        }
        
        // 5. Clean up Em-Dash pileups (Turnitout punctuation rule)
        let emDashRegex = try? NSRegularExpression(pattern: #"\s*—\s*"#, options: [])
        if let emDash = emDashRegex {
            let matches = emDash.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
            if matches.count >= 2 {
                working = emDash.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: ", ")
                edits.append("Normalized \(matches.count) em-dashes (—) into standard punctuation")
            }
        }
        
        // 6. Rotate discourse markers to avoid repetitive openers
        for (marker, alts) in discourseRotations {
            let pat = "\\b\(marker),\\s+"
            if let r = try? NSRegularExpression(pattern: pat, options: []) {
                let matches = r.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
                if matches.count > 1 {
                    var idx = 0
                    // Rotate alternative
                    working = r.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: "\(alts[idx % alts.count]), ")
                    idx += 1
                    edits.append("Rotated discourse marker '\(marker)' across sentences")
                }
            }
        }
        
        // 7. Tier-3 Adversarial Perplexity Waveform Injection (DetectGPT Evasion)
        if adversarialSpikes {
            let spikeRes = PerplexitySpikeEngine.injectSpikes(text: working)
            working = spikeRes.spikedText
            edits.append(contentsOf: spikeRes.spikeNotes)
        }
        
        // 8. Frontier 4: Author Profile Stylometric Voice Alignment
        if let profile = authorProfile, profile.sampleWordCount >= 30 {
            if profile.contractionRate < 0.04 {
                // Author prefers formal writing: unroll contractions
                var changedCount = 0
                for pair in unrollContractions {
                    if let regex = try? NSRegularExpression(pattern: pair.pattern, options: []) {
                        let matches = regex.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
                        if !matches.isEmpty {
                            working = regex.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: pair.replacement)
                            changedCount += matches.count
                        }
                    }
                }
                if changedCount > 0 {
                    edits.append("Unrolled \(changedCount) contractions to match author's formal register")
                }
            } else if profile.contractionRate > 0.12 {
                // Author prefers conversational style: roll contractions
                var changedCount = 0
                for pair in rollContractions {
                    if let regex = try? NSRegularExpression(pattern: pair.pattern, options: []) {
                        let matches = regex.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
                        if !matches.isEmpty {
                            working = regex.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: pair.replacement)
                            changedCount += matches.count
                        }
                    }
                }
                if changedCount > 0 {
                    edits.append("Contracted \(changedCount) verb forms to match author's conversational voice")
                }
            }
        }
        
        // 9. Restore protected LaTeX and Code zones
        let restored = TextNormalizer.restoreProtectedZones(working, placeholders: placeholders)
        
        let origWordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let newWordCount = restored.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let delta = newWordCount - origWordCount
        
        return DeterministicHumanizeResult(
            transformedText: restored,
            editsApplied: edits,
            purgedWatermarks: watermarkCount,
            wordCountDelta: delta
        )
    }
}
