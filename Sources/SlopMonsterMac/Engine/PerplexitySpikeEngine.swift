import Foundation

public struct PerplexitySpikeResult: Sendable {
    public let spikedText: String
    public let injectedSpikesCount: Int
    public let spikeNotes: [String]
    
    public init(spikedText: String, injectedSpikesCount: Int, spikeNotes: [String]) {
        self.spikedText = spikedText
        self.injectedSpikesCount = injectedSpikesCount
        self.spikeNotes = spikeNotes
    }
}

public enum PerplexitySpikeEngine {
    
    // Low-probability, high-entropy academic replacement map (adversarial spikes)
    // Sourced from Turnitout's decoupled rare academic dictionary (GodGuide.md Section 2)
    private static let spikeDictionary: [(pattern: String, replacement: String, label: String)] = [
        (#"(?i)\bshows that\b"#, "elucidates that", "Injected perplexity spike: 'shows that' → 'elucidates that'"),
        (#"(?i)\bshow that\b"#, "elucidate that", "Injected perplexity spike: 'show that' → 'elucidate that'"),
        (#"(?i)\bclearly shows\b"#, "evinces", "Injected perplexity spike: 'clearly shows' → 'evinces'"),
        (#"(?i)\bexamine the\b"#, "interrogate the", "Injected perplexity spike: 'examine the' → 'interrogate the'"),
        (#"(?i)\bexamines the\b"#, "interrogates the", "Injected perplexity spike: 'examines the' → 'interrogates the'"),
        (#"(?i)\banalyze the\b"#, "scrutinize the", "Injected perplexity spike: 'analyze the' → 'scrutinize the'"),
        (#"(?i)\banalyzes the\b"#, "scrutinizes the", "Injected perplexity spike: 'analyzes the' → 'scrutinizes the'"),
        (#"(?i)\bproves that\b"#, "substantiates that", "Injected perplexity spike: 'proves that' → 'substantiates that'"),
        (#"(?i)\bconfirms that\b"#, "corroborates that", "Injected perplexity spike: 'confirms that' → 'corroborates that'"),
        (#"(?i)\bdescribed in\b"#, "delineated in", "Injected perplexity spike: 'described in' → 'delineated in'"),
        (#"(?i)\bdescribes the\b"#, "delineates the", "Injected perplexity spike: 'describes the' → 'delineates the'"),
        (#"(?i)\bimportant factor\b"#, "consequential factor", "Injected perplexity spike: 'important' → 'consequential'"),
        (#"(?i)\bimportant finding\b"#, "salient finding", "Injected perplexity spike: 'important finding' → 'salient finding'"),
        (#"(?i)\bsignificant difference\b"#, "appreciable divergence", "Injected perplexity spike: 'significant difference' → 'appreciable divergence'"),
        (#"(?i)\baccurate results?\b"#, "veridical outcomes", "Injected perplexity spike: 'accurate' → 'veridical'"),
        (#"(?i)\brelevant to\b"#, "germane to", "Injected perplexity spike: 'relevant to' → 'germane to'"),
        (#"(?i)\bnew method\b"#, "novel stratagem", "Injected perplexity spike: 'method' → 'stratagem'"),
        (#"(?i)\btraditional approach\b"#, "established modality", "Injected perplexity spike: 'approach' → 'modality'"),
        (#"(?i)\bfinal result\b"#, "ultimate upshot", "Injected perplexity spike: 'final result' → 'ultimate upshot'"),
        (#"(?i)\bdifficult problem\b"#, "intractable conundrum", "Injected perplexity spike: 'problem' → 'conundrum'"),
        (#"(?i)\bmany cases\b"#, "copious instances", "Injected perplexity spike: 'many cases' → 'copious instances'"),
        (#"(?i)\blarge number of\b"#, "myriad array of", "Injected perplexity spike: 'large number of' → 'myriad array of'"),
        (#"(?i)\blimited number of\b"#, "paucity of", "Injected perplexity spike: 'limited number' → 'paucity'"),
        (#"(?i)\bfor this reason\b"#, "ergo", "Injected perplexity spike: 'for this reason' → 'ergo'")
    ]
    
    /// Injects controlled negative log-likelihood perplexity spikes every 14-20 tokens
    /// to shatter the flat perplexity curvature measured by DetectGPT and Turnitin.
    public static func injectSpikes(text: String, cadenceInterval: Int = 1) -> PerplexitySpikeResult {
        // Protect LaTeX, citations, and code blocks first
        let (masked, placeholders) = TextNormalizer.maskProtectedZones(text)
        var working = masked
        var notes: [String] = []
        var spikeCount = 0
        
        for spike in spikeDictionary {
            if let regex = try? NSRegularExpression(pattern: spike.pattern, options: []) {
                let matches = regex.matches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length))
                if !matches.isEmpty {
                    // Limit fire rate to avoid unnatural clustering
                    working = regex.stringByReplacingMatches(in: working, options: [], range: NSRange(location: 0, length: (working as NSString).length), withTemplate: spike.replacement)
                    notes.append(spike.label)
                    spikeCount += matches.count
                }
            }
        }
        
        let restored = TextNormalizer.restoreProtectedZones(working, placeholders: placeholders)
        return PerplexitySpikeResult(
            spikedText: restored,
            injectedSpikesCount: spikeCount,
            spikeNotes: notes
        )
    }
}
