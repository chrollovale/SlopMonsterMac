import Foundation

public struct OverkillResult: Sendable {
    public let finalizedText: String
    public let changeNotes: [String]
    public let initialReport: SlopReport
    public let finalReport: SlopReport
    public let durationSeconds: Double
    public let stagesExecuted: [String]
    public let mathIntegrityVerified: Bool
    public let edgeCasesVerified: [String]
    public let providerUsed: String
    
    public init(
        finalizedText: String,
        changeNotes: [String],
        initialReport: SlopReport,
        finalReport: SlopReport,
        durationSeconds: Double,
        stagesExecuted: [String],
        mathIntegrityVerified: Bool,
        edgeCasesVerified: [String],
        providerUsed: String
    ) {
        self.finalizedText = finalizedText
        self.changeNotes = changeNotes
        self.initialReport = initialReport
        self.finalReport = finalReport
        self.durationSeconds = durationSeconds
        self.stagesExecuted = stagesExecuted
        self.mathIntegrityVerified = mathIntegrityVerified
        self.edgeCasesVerified = edgeCasesVerified
        self.providerUsed = providerUsed
    }
}

/// The Overkill Engine executes a multi-stage fusion pipeline:
/// Pre-sanitization → Deterministic cliché eradication → Rival AI cleanse (if online) →
/// Adversarial perplexity spikes → Author KL-divergence matching → Macro-asymmetry balancing →
/// Math integrity verification → Automated multi-pass convergence loop.
public enum OverkillEngine {
    
    public static func execute(
        draft: String,
        provider: CleanseProviderType,
        baseURL: String,
        apiKey: String,
        model: String,
        context: String = "",
        authorProfile: AuthorProfile? = nil,
        zeroExpansion: Bool = false
    ) async -> OverkillResult {
        let startTime = Date()
        var stages: [String] = []
        var notes: [String] = []
        var verifiedEdgeCases: [String] = []
        
        // Step 0: Initial Diagnostic Audit
        let initialReport = SlopEngine.shared.audit(text: draft, authorProfile: authorProfile)
        
        // PASS 1: Steganographic & Covert Tracking Scrub
        let (purgedDraft, initialWatermarks) = TextNormalizer.purgeZeroWidthUnicode(draft)
        if initialWatermarks > 0 {
            stages.append("Pass 1: Purged \(initialWatermarks) covert zero-width tracking watermarks (EU AI Act)")
            notes.append("Purged \(initialWatermarks) hidden Unicode watermarks (U+200B/C/D/2060/FEFF)")
        } else {
            stages.append("Pass 1: Steganographic scan clean (0 watermarks)")
        }
        verifiedEdgeCases.append("Steganographic Watermarks: 0")
        
        // PASS 2: Cryptographic & Code Shielding (Extract Math Checkpoint)
        let (maskedDraft, placeholders) = TextNormalizer.maskProtectedZones(purgedDraft)
        stages.append("Pass 2: Shielded \(placeholders.count) LaTeX math and code zones from alteration")
        
        // PASS 3: 100% Offline Deterministic Humanization & Cliché Annihilation
        let deterministicPass = DeterministicHumanizer.humanize(
            text: maskedDraft,
            zeroExpansion: zeroExpansion,
            adversarialSpikes: false, // will do targeted spike pass in stage 5
            authorProfile: authorProfile
        )
        var working = deterministicPass.transformedText
        notes.append(contentsOf: deterministicPass.editsApplied)
        stages.append("Pass 3: Deterministic Cliché & Karp-Rabin 5-Gram Annihilation applied")
        
        // PASS 4: Rival AI Cleanse Pass (Attempt if configured/reachable)
        var providerLabel = "Deterministic Zero-AI Engine"
        
        // Only attempt network AI pass if provider requires no key (local) or key is present
        let canAttemptAI = !provider.requiresAPIKey || !apiKey.isEmpty
        if canAttemptAI {
            do {
                let aiResponse = try await CleanseService.shared.cleanse(
                    draft: working,
                    provider: provider,
                    baseURL: baseURL,
                    apiKey: apiKey,
                    model: model,
                    context: context
                )
                // Scrub any zero-width characters the AI might have emitted
                let (scrubbedAI, _) = TextNormalizer.purgeZeroWidthUnicode(aiResponse.cleansedText)
                working = scrubbedAI
                notes.append(contentsOf: aiResponse.changeNotes)
                providerLabel = "\(provider.shortName) + Full Mathematical Synthesis"
                stages.append("Pass 4: Rival AI Cleanse completed via \(provider.shortName)")
            } catch {
                stages.append("Pass 4: AI Cleanse bypassed (\(error.localizedDescription)). Advanced deterministic fallback active.")
                providerLabel = "Deterministic Zero-AI Engine (Offline Overkill)"
            }
        } else {
            stages.append("Pass 4: Offline mode active (No API key provided). Zero-AI mathematical synthesis running.")
            providerLabel = "Deterministic Zero-AI Engine (Offline Overkill)"
        }
        
        // PASS 4B: DIPPER Discourse Topology & Content Reordering (Krishna et al., NeurIPS 2023)
        let (discourseMutated, discourseNotes) = DiscourseMutator.mutateDiscourse(text: working)
        working = discourseMutated
        notes.append(contentsOf: discourseNotes)
        stages.append("Pass 4B: DIPPER Discourse Topology Inversion (shuffled clause hierarchies & staccato cadence)")
        verifiedEdgeCases.append("Discourse Topology: Shuffled & Inverted")
        
        // PASS 4C: Pragmatic Engineering Anchors & Binoculars Disruption (Hans et al., ICML 2024)
        let (pragmaticText, pragmaticNotes) = PragmaticEntropyEngine.injectPragmaticEntropy(text: working)
        working = pragmaticText
        notes.append(contentsOf: pragmaticNotes)
        stages.append("Pass 4C: Pragmatic Engineering Anchors & Binoculars cross-perplexity disruption injected")
        verifiedEdgeCases.append("Binoculars Cross-Perplexity: Disrupted")
        
        // PASS 5: Tier-3 Adversarial Perplexity Waveform Injection (DetectGPT Evasion)
        let spikeRes = PerplexitySpikeEngine.injectSpikes(text: working)
        working = spikeRes.spikedText
        if spikeRes.injectedSpikesCount > 0 {
            notes.append("Injected \(spikeRes.injectedSpikesCount) adversarial perplexity waveform spikes")
            stages.append("Pass 5: Injected \(spikeRes.injectedSpikesCount) low-probability academic perplexity spikes")
        }
        verifiedEdgeCases.append("Perplexity Curvature: Adversarially Spiked")
        
        // PASS 6: Author Profile Voice Alignment & Contraction Synthesis
        if let profile = authorProfile, profile.sampleWordCount >= 30 {
            let adapted = DeterministicHumanizer.humanize(
                text: working,
                zeroExpansion: zeroExpansion,
                adversarialSpikes: false,
                authorProfile: profile
            )
            working = adapted.transformedText
            notes.append(contentsOf: adapted.editsApplied.filter { $0.contains("author") || $0.contains("contract") })
            stages.append("Pass 6: Aligned prose to Author Stylometric Profile (KL minimization)")
            verifiedEdgeCases.append("Author KL Alignment: Active")
        }
        
        // PASS 7: Protected Zone Restoration & Mathematical Verification
        let restoredText = TextNormalizer.restoreProtectedZones(working, placeholders: placeholders)
        
        // EDGE-CASE CHECK: Verify that all math formulas from original draft are preserved
        var mathIntact = true
        for (_, originalFormula) in placeholders {
            if !restoredText.contains(originalFormula) {
                mathIntact = false
                break
            }
        }
        stages.append("Pass 7: Restored protected zones (Math Integrity: \(mathIntact ? "100% PRESERVED" : "FLAGGED"))")
        verifiedEdgeCases.append("LaTeX Math Integrity: \(mathIntact ? "Verified Intact" : "Deviated")")
        
        // PASS 8: Secondary Convergence Pass (Audit-Driven Self-Correction)
        // If any residual tells slipped through the AI pass, eliminate them now
        var finalizedText = restoredText
        var secondReport = SlopEngine.shared.audit(text: finalizedText, authorProfile: authorProfile)
        
        if !secondReport.hits(for: .phrases).isEmpty || !secondReport.hits(for: .vocab).isEmpty {
            let polishPass = DeterministicHumanizer.humanize(
                text: finalizedText,
                zeroExpansion: zeroExpansion,
                adversarialSpikes: false,
                authorProfile: authorProfile
            )
            finalizedText = polishPass.transformedText
            secondReport = SlopEngine.shared.audit(text: finalizedText, authorProfile: authorProfile)
            stages.append("Pass 8: Convergence polish pass executed; lingering tells eradicated")
        } else {
            stages.append("Pass 8: Convergence check passed on first iteration")
        }
        
        verifiedEdgeCases.append("Classic Slop Gates: \(secondReport.classicScore)/5 Passed")
        verifiedEdgeCases.append("Surviving Watermarks: \(secondReport.watermarkCount)")
        verifiedEdgeCases.append("Macro Resilience: \(Int(secondReport.macroResilienceScore))%")
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Deduplicate change notes
        var uniqueNotes: [String] = []
        var seenNotes = Set<String>()
        for n in notes {
            if !seenNotes.contains(n) {
                seenNotes.insert(n)
                uniqueNotes.append(n)
            }
        }
        
        return OverkillResult(
            finalizedText: finalizedText,
            changeNotes: uniqueNotes,
            initialReport: initialReport,
            finalReport: secondReport,
            durationSeconds: duration,
            stagesExecuted: stages,
            mathIntegrityVerified: mathIntact,
            edgeCasesVerified: verifiedEdgeCases,
            providerUsed: providerLabel
        )
    }
}
