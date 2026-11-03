import Foundation

/// Injects pragmatic engineering caveats, parenthetical digressions, and conversational anchors
/// to defeat Binoculars cross-perplexity ratio tests (Hans et al., ICML 2024) and DeBERTa supervised detectors.
///
/// **Why this works against Binoculars and GPTZero:**
/// Binoculars computes the ratio of perplexity across two language models ($PPL_1 / PPL_2$).
/// LLMs invariably select tokens from their top-p probability cone, keeping the cross-perplexity
/// ratio strictly inside the "Machine" cluster.
///
/// Authentic human writing features **pragmatic digressions, skeptical qualifications, and parenthetical asides**.
/// These linguistic markers carry high semantic naturalness to human readers, but represent
/// zero-probability transitions under a standard LLM's next-token generation distribution,
/// blowing the Binoculars ratio cleanly past the human threshold.
public enum PragmaticEntropyEngine {
    
    // Pragmatic technical qualifications that humans naturally use but LLMs rarely emit without prompting
    private static let pragmaticReplacements: [(pattern: String, replacement: String, label: String)] = [
        (
            #"(?i)\bis not just a ([^,]+), it is a ([^.]+)\b"#,
            "Rather than viewing this merely as a $1, in practice it functions as a $2",
            "Injected pragmatic engineering framing: 'Rather than viewing this merely as...'"
        ),
        (
            #"(?i)\bseamlessly elevates transaction pipelining\b"#,
            "streamlines transaction pipelining—though network jitter still dictates tail latency",
            "Injected pragmatic trade-off qualifier regarding tail latency"
        ),
        (
            #"(?i)\bdelivers unprecedented throughput\b"#,
            "yields substantial throughput gains in production environments",
            "Replaced hyperbolic claim with grounded empirical qualification"
        ),
        (
            #"(?i)\beffortlessly revolutionizes\b"#,
            "substantially improves operational efficiency",
            "Replaced marketing hyperbole with sober technical assessment"
        ),
        (
            #"(?i)\bunlocks unmatched fairness\b"#,
            "establishes a demonstrably more equitable auction dynamic",
            "Replaced 'unlocks unmatched fairness' with precise game-theoretic terminology"
        ),
        (
            #"(?i)\bis a game-changing framework\b"#,
            "serves as a practical architectural pattern",
            "Replaced 'game-changing framework' with grounded engineering phrasing"
        ),
        (
            #"(?i)\bAt the end of the day, say goodbye to\b"#,
            "In real-world deployments, this largely mitigates",
            "Replaced conversational cliché with empirical field observation"
        ),
        (
            #"(?i)\bstands as a testament to engineering excellence\b"#,
            "reflects deliberate trade-offs across consensus constraints",
            "Replaced empty praise with engineering realism"
        )
    ]
    
    // Human parenthetical digressions to break the textbook rhythm of long paragraphs
    private static let humanParentheticals: [(trigger: String, aside: String)] = [
        ("Galois field", " (specifically over fields where fast Walsh-Hadamard transforms apply)"),
        ("BLS12-381", " (chosen for its 128-bit security margin and optimized G2 scalar multiplication)"),
        ("Groth16", " (which requires a trusted setup, albeit with minimal proof byte size)"),
        ("Gossipsub v1.1", " (as benchmarked in large-scale testnet conditions)"),
        ("KZG polynomial commitments", " (which trade off constant proof size for trusted multi-party setup ceremony)")
    ]
    
    /// Injects pragmatic technical qualifications, parenthetical asides, and human conversational anchors.
    public static func injectPragmaticEntropy(text: String) -> (transformed: String, notes: [String]) {
        // Protect math and code blocks first
        let (masked, placeholders) = TextNormalizer.maskProtectedZones(text)
        var working = masked
        var notes: [String] = []
        
        // 1. Apply pragmatic replacements
        for item in pragmaticReplacements {
            if let regex = try? NSRegularExpression(pattern: item.pattern, options: []) {
                let range = NSRange(location: 0, length: (working as NSString).length)
                let matches = regex.matches(in: working, options: [], range: range)
                if !matches.isEmpty {
                    working = regex.stringByReplacingMatches(in: working, options: [], range: range, withTemplate: item.replacement)
                    notes.append(item.label)
                }
            }
        }
        
        // 2. Injected targeted technical parenthetical digressions (1-2 max per text to avoid clutter)
        var parentheticalsInjected = 0
        for item in humanParentheticals {
            guard parentheticalsInjected < 2 else { break }
            if working.contains(item.trigger) && !working.contains(item.aside) {
                if let r = working.range(of: item.trigger) {
                    working.insert(contentsOf: item.aside, at: r.upperBound)
                    notes.append("Injected human parenthetical aside: '\(item.aside.trimmingCharacters(in: .whitespaces))'")
                    parentheticalsInjected += 1
                }
            }
        }
        
        // 3. Restore protected zones
        let restored = TextNormalizer.restoreProtectedZones(working, placeholders: placeholders)
        return (restored, notes)
    }
}
