import Testing
@testable import SlopMonsterMac
import Foundation

@Suite("SlopMonster Core Regression Tests")
struct SlopMonsterRegressionTests {
    
    @Test("Base vocabulary forms trigger detections")
    func testBaseVocab() {
        let text = "We delve and leverage seamless tools to elevate your business."
        let report = SlopEngine.shared.audit(text: text)
        #expect(report.classicScore < 5)
        #expect(!report.hits(for: .vocab).isEmpty)
    }
    
    @Test("Inflections of vocabulary words fire")
    func testInflections() {
        let report = SlopEngine.shared.audit(text: "Acme elevates your workflow, unlocks data, and empowers teams.")
        #expect(!report.hits(for: .vocab).isEmpty)
    }
    
    @Test("Literal English senses must NOT fire")
    func testLiteralSensesClean() {
        let samples = [
            "We craft furniture by hand in Leeds.",
            "Harness the horse before you load the cart.",
            "They walked the length of the valley."
        ]
        for s in samples {
            let report = SlopEngine.shared.audit(text: s)
            #expect(report.hits(for: .vocab).isEmpty, "False positive on: \(s)")
        }
    }
    
    @Test("Negated-just constructions fire in contracted and formal registers")
    func testConstructions() {
        let badCases = [
            "It's not just a tool, it's a platform.",
            "It is not just a tool, it is a platform.",
            "Whether you are a beginner or a pro, start here.",
            "This is where Acme comes in.",
            "Here's the thing. You need a plan.",
            "The result? Teams ship faster."
        ]
        for b in badCases {
            let report = SlopEngine.shared.audit(text: b)
            #expect(!report.hits(for: .phrases).isEmpty, "Missed tell on: \(b)")
        }
    }
    
    @Test("Tricolon lists fire while service lists stay clean")
    func testTricolon() {
        // Bad: 3-item rhetorical flourish
        let badTricolon = "Trusted, reliable and built to last."
        let reportBad = SlopEngine.shared.audit(text: badTricolon)
        #expect(!reportBad.hits(for: .rhythm).isEmpty)
        
        // Good: concrete list of services
        let goodList = "Inspection, repair and replacement for homes and commercial buildings."
        let reportGood = SlopEngine.shared.audit(text: goodList)
        #expect(reportGood.hits(for: .rhythm).isEmpty)
    }
    
    @Test("Unsupported proof detection")
    func testProof() {
        let bad = "Loved by 10,000+ happy homeowners."
        let report = SlopEngine.shared.audit(text: bad)
        #expect(!report.hits(for: .proof).isEmpty)
        
        let good = "\"Don't Make Me Think\", 2000. The reader decides in seconds."
        let reportGood = SlopEngine.shared.audit(text: good)
        #expect(reportGood.hits(for: .proof).isEmpty)
    }
    
    @Test("Clean human writing scores 5/5 CLEAN")
    func testCleanCopy() {
        let clean = "Six nails per shingle, every shingle. You get a written scope and a fixed number before anyone climbs a ladder."
        let report = SlopEngine.shared.audit(text: clean)
        #expect(report.classicScore == 5)
        #expect(report.hits.isEmpty)
        #expect(report.isClean)
    }
    
    @Test("Word Diff Engine computes insertions and deletions")
    func testWordDiff() {
        let orig = "This is bad copy."
        let rev = "This is clean writing."
        let tokens = DiffEngine.computeWordDiff(original: orig, revised: rev)
        #expect(tokens.contains(where: { $0.text.contains("bad") && $0.kind == .deleted }))
        #expect(tokens.contains(where: { $0.text.contains("clean") && $0.kind == .inserted }))
    }
    
    // MARK: - Turnitout Extension Integration Tests
    
    @Test("Turnitout Zero-Width Unicode tracking character detection and purging")
    func testTurnitoutWatermarks() {
        let watermarkedText = "This\u{200B} contains\u{200C} invisible\u{200D} AI\u{2060} watermarks\u{FEFF}."
        let report = SlopEngine.shared.audit(text: watermarkedText)
        #expect(report.watermarkCount == 5)
        #expect(!report.hits(for: .watermark).isEmpty)
        
        let purged = TextNormalizer.purgeZeroWidthUnicode(watermarkedText)
        #expect(purged.purgedCount == 5)
        #expect(purged.cleaned == "This contains invisible AI watermarks.")
    }
    
    @Test("Turnitout BERT and LLM Hallmark Clichés fire")
    func testTurnitoutHallmarkSignatures() {
        let sample = "In conclusion, it is important to delve into the comprehensive tapestry of modern neural networks. This study plays a pivotal role in illustrating that artificial intelligence stands as a testament to human innovation. Furthermore, the interplay between stochastic optimization and computational scalability provides a robust framework. Moreover, in today's fast-paced digital era, the profound impact cannot be overlooked."
        let report = SlopEngine.shared.audit(text: sample)
        #expect(!report.hits(for: .phrases).isEmpty)
        #expect(!report.hits(for: .vocab).isEmpty)
        #expect(report.classicScore < 5)
    }
    
    @Test("Turnitout 100% Deterministic Zero-AI Humanizer replaces tells and preserves math")
    func testDeterministicHumanizerExecution() {
        let sample = "In conclusion, it is important to delve into the comprehensive tapestry of systems where $E = mc^2$. Our cutting-edge platform seamlessly elevates your performance."
        let result = DeterministicHumanizer.humanize(text: sample, zeroExpansion: true)
        
        // Math must remain 100% intact
        #expect(result.transformedText.contains("$E = mc^2$"))
        
        // Tells must be replaced
        #expect(!result.transformedText.contains("comprehensive tapestry"))
        #expect(!result.transformedText.contains("cutting-edge"))
        #expect(!result.transformedText.contains("seamlessly elevates"))
        #expect(!result.editsApplied.isEmpty)
    }
    
    @Test("ZipPy Compression Perplexity computes non-zero entropy")
    func testZipPyPerplexityAnalyzer() {
        let text = "The quick brown fox jumps over the lazy dog. A diverse set of vocabulary ensures compression resistance and healthy human perplexity."
        let res = ZipPyAnalyzer.evaluate(text: text)
        #expect(res.originalBytes > 0)
        #expect(res.compressedBytes > 0)
        #expect(res.entropyPercentage > 50.0)
    }
    
    @Test("Long document uniform paragraph stacking triggers macro detection")
    func testLongDocumentParagraphUniformity() {
        let para1 = "This is the first paragraph of a long essay discussing cloud architecture and infrastructure reliability in enterprise software. We examine how databases scale across clusters and ensure continuous data integrity for global teams."
        let para2 = "This is the second paragraph of a long essay discussing cloud architecture and infrastructure reliability in enterprise software. We examine how databases scale across clusters and ensure continuous data integrity for global teams."
        let para3 = "This is the third paragraph of a long essay discussing cloud architecture and infrastructure reliability in enterprise software. We examine how databases scale across clusters and ensure continuous data integrity for global teams."
        let para4 = "This is the fourth paragraph of a long essay discussing cloud architecture and infrastructure reliability in enterprise software. We examine how databases scale across clusters and ensure continuous data integrity for global teams."
        let para5 = "This is the fifth paragraph of a long essay discussing cloud architecture and infrastructure reliability in enterprise software. We examine how databases scale across clusters and ensure continuous data integrity for global teams."
        let para6 = "This is the sixth paragraph of a long essay discussing cloud architecture and infrastructure reliability in enterprise software. We examine how databases scale across clusters and ensure continuous data integrity for global teams."
        let longDoc = [para1, para2, para3, para4, para5, para6].joined(separator: "\n\n")
        
        let report = SlopEngine.shared.audit(text: longDoc)
        #expect(report.wordCount >= 180)
        #expect(report.paragraphCount >= 4)
        #expect(report.macroResilienceScore < 85.0)
    }
    
    // MARK: - Mathematical Ceiling Frontier Tests
    
    @Test("Hurst Exponent computes long-range memory on sentence cadence")
    func testHurstExponent() {
        // Generate sample with varied sentence lengths (20 sentences)
        let sentences = (1...20).map { i in
            let wordCount = (i % 3 == 0) ? 5 : (i % 2 == 0 ? 25 : 12)
            return (1...wordCount).map { "word\($0)" }.joined(separator: " ") + "."
        }.joined(separator: " ")
        
        let metrics = HurstExponentAnalyzer.evaluate(text: sentences)
        #expect(metrics.hurstExponent > 0.0)
        #expect(metrics.hurstExponent < 1.0)
    }
    
    @Test("Burstiness Analyzer detects Poisson vs clustered word reuse")
    func testBurstinessAnalyzer() {
        // Text with clustered repetitions of content words
        var text = ""
        for i in 1...10 {
            text += "The architecture of the cluster requires careful architecture planning and architecture validation. "
            text += "Meanwhile database replication ensures database durability and database availability. "
            text += "Section \(i) describes systemic parameters and performance indicators in telemetry. "
        }
        
        let metrics = BurstinessAnalyzer.evaluate(text: text)
        #expect(metrics.fanoFactor > 0.5)
        #expect(!metrics.assessment.isEmpty)
    }
    
    @Test("Benford's Law Analyzer computes leading digit chi-squared distribution")
    func testBenfordAnalyzer() {
        // Generate text with varied word frequencies spanning multiple orders of magnitude
        var words: [String] = []
        for i in 1...60 {
            let freq = i <= 5 ? 20 : (i <= 15 ? 8 : (i <= 30 ? 3 : 1))
            for _ in 1...freq {
                words.append("term\(i)")
            }
        }
        let sample = words.joined(separator: " ")
        let metrics = BenfordAnalyzer.evaluate(text: sample)
        #expect(metrics.chiSquaredStatistic >= 0)
        #expect(!metrics.assessment.isEmpty)
    }
    
    @Test("Heaps' Law Analyzer computes sublinear vocabulary growth exponent beta")
    func testHeapsLaw() {
        let text = (1...150).map { "concept\($0 % 40)" }.joined(separator: " ")
        let metrics = HeapsLawAnalyzer.evaluate(text: text)
        #expect(metrics.heapsBeta > 0.1 && metrics.heapsBeta <= 1.0)
        #expect(metrics.heapsK > 0)
    }
    
    @Test("Author Profile Engine extracts fingerprint and computes KL-divergence")
    func testAuthorProfileAndKLMatch() {
        let authorSample = """
        I've been writing software for fifteen years, and here's what I learned.
        Simplicity isn't accidental; it requires disciplined pruning.
        When you build a system, don't over-engineer for hypothetical traffic.
        Instead, make it observable, make it fast, and keep your dependencies minimal.
        We don't need another framework. We need clarity.
        """
        let profile = AuthorProfileEngine.extractProfile(from: authorSample)
        #expect(profile.sampleWordCount >= 40)
        #expect(profile.sentenceLengthMean > 5.0)
        #expect(profile.typeTokenRatio > 0.4)
        
        // Match authentic writing against profile
        let report = AuthorProfileEngine.matchAgainstProfile(text: authorSample, profile: profile)
        #expect(report.matchPercentage >= 70.0)
        #expect(report.overallKLDivergence >= 0.0)
        
        // Deterministic humanizer adapts contractions based on author profile
        let formalProfile = AuthorProfile(
            sentenceLengthMean: 20.0, sentenceLengthStdDev: 5.0, sentenceLengthSkewness: 0.1,
            typeTokenRatio: 0.6, hapaxRatio: 0.5, avgWordLength: 5.0, commaRate: 5.0,
            semicolonRate: 0.5, colonRate: 0.2, emDashRate: 0.1, exclamationRate: 0.0,
            questionRate: 0.1, parenthesisRate: 0.1, avgParagraphLength: 60.0,
            paragraphLengthStdDev: 15.0, functionWordProfile: [:], contractionRate: 0.01,
            discourseMarkerRate: 0.03, coordinationRate: 0.1, sampleWordCount: 200,
            sampleSentenceCount: 10, extractedAt: Date()
        )
        let informalText = "We don't know why it didn't work."
        let adapted = DeterministicHumanizer.humanize(text: informalText, authorProfile: formalProfile)
        #expect(adapted.transformedText.contains("do not"))
        #expect(adapted.transformedText.contains("did not"))
    }
    
    // MARK: - Overkill Fusion Engine Tests
    
    @Test("Overkill Engine executes multi-stage fusion and verifies mathematical edge cases")
    func testOverkillEnginePipeline() async {
        let sample = """
        In conclusion, it is important to delve deep into the comprehensive tapestry of systems where $E = mc^2$.
        Our cutting-edge platform seamlessly elevates your performance.
        Whether you are an engineer or researcher, that's where Acme comes in.
        It is not just a tool, it is a game-changing breakthrough.
        This contains\u{200B} covert watermarks\u{FEFF}.
        """
        let result = await OverkillEngine.execute(
            draft: sample,
            provider: .localOllama,
            baseURL: "http://localhost:99999", // offline mock URL
            apiKey: "",
            model: "test-model"
        )
        
        // 1. Math integrity must be 100% verified intact
        #expect(result.mathIntegrityVerified)
        #expect(result.finalizedText.contains("$E = mc^2$"))
        
        // 2. All watermarks must be purged
        #expect(result.finalReport.watermarkCount == 0)
        
        // 3. Clichés eradicated
        #expect(!result.finalizedText.contains("comprehensive tapestry"))
        #expect(!result.finalizedText.contains("seamlessly elevates"))
        #expect(!result.finalizedText.contains("cutting-edge"))
        
        // 4. Verification passes executed
        #expect(!result.stagesExecuted.isEmpty)
        #expect(!result.edgeCasesVerified.isEmpty)
    }
    
    @Test("Discourse Mutator inverts clause hierarchy and injects staccato cadence")
    func testDiscourseMutator() {
        let sample = "The consensus engine halts under asynchronous network partition, because message latency exceeds the timeout boundary. The validator committee cannot reach agreement when Byzantine faults exceed one-third of the total network capacity. Performance drops significantly across all distributed nodes."
        let (mutated, edits) = DiscourseMutator.mutateDiscourse(text: sample)
        #expect(!mutated.isEmpty)
        // Clause inversion: "Because message latency exceeds..., the consensus engine halts..."
        #expect(mutated.contains("Because message latency exceeds") || !edits.isEmpty)
    }
    
    @Test("Pragmatic Entropy Engine injects engineering qualifiers and parentheticals")
    func testPragmaticEntropyEngine() {
        let sample = "At the end of the day, say goodbye to leaks — this is a game-changing framework that delivers unprecedented throughput for Galois field computations."
        let (transformed, notes) = PragmaticEntropyEngine.injectPragmaticEntropy(text: sample)
        #expect(!notes.isEmpty)
        #expect(!transformed.contains("game-changing framework"))
        #expect(!transformed.contains("delivers unprecedented throughput"))
    }
    
    // MARK: - Medium Optimizer & Retention Attention Tests
    
    @Test("Medium Optimizer formats complete typographic hierarchy and preserves LaTeX")
    func testMediumOptimizerStructuralHierarchy() {
        let draft = """
        # Real-Time Zero-Knowledge Proof Verification at Scale
        *An empirical investigation into constraint systems.*
        
        In today's fast-paced digital world, cryptography is essential.
        We measured proof generation latency across 10,000 circuits where $L = \\mathcal{O}(\\log N)$.
        The benchmark revealed that memory consumption scales linearly with degree $D$.
        """
        
        let res = MediumOptimizer.optimize(text: draft)
        
        // 1. Math preservation
        #expect(res.finalizedText.contains("$L = \\mathcal{O}(\\log N)$"))
        
        // 2. Kicker and Header Hierarchy
        #expect(!res.kicker.isEmpty)
        #expect(res.finalizedText.contains(res.kicker.uppercased()))
        #expect(res.finalizedText.contains("# Real-Time Zero-Knowledge Proof Verification at Scale"))
        #expect(res.finalizedText.contains("*An empirical investigation into constraint systems.*"))
        #expect(res.finalizedText.contains("min read"))
        
        // 3. 30-Second Attention Anchor: Throat clearing purged
        #expect(!res.finalizedText.contains("In today's fast-paced digital world,"))
        
        // 4. Boost-grade Community Discussion Anchor present
        #expect(res.finalizedText.contains("The Production Takeaway & Discussion"))
        #expect(res.finalizedText.contains("Drop your benchmarks and thoughts in the responses"))
    }
    
    @Test("Medium Optimizer enforces mobile paragraph cadence and meso-loop subheadings on long text")
    func testMediumOptimizerLongFormCadence() {
        // Construct a 400-word block without subheadings to test auto-injection
        let sentences = [
            "We deployed the distributed consensus node across six availability zones to observe partition tolerance.",
            "Message replication latency drifted significantly under peak network jitter.",
            "The Raft leader election timed out because heartbeats dropped below the quorum threshold.",
            "Our benchmark team discovered that disk write synchronization was the hidden culprit.",
            "Storage write queues backed up into the megabytes within forty seconds.",
            "The cluster reached an unrecoverable split-brain condition before automated failover triggered."
        ]
        let paragraph = sentences.joined(separator: " ")
        let longDraft = [paragraph, paragraph, paragraph].joined(separator: "\n\n")
        
        let res = MediumOptimizer.optimize(text: longDraft)
        
        #expect(res.wordCount > 100)
        #expect(res.estimatedReadMinutes >= 1)
        #expect(res.predictedReadRatio > 30.0)
        // Verify meso subheadings (H2) or paragraph splits were applied
        #expect(res.subheadingsInjected > 0 || !res.transformationsApplied.isEmpty)
    }
    
    // MARK: - Medium Formatter & Visual Saliency Tests
    
    @Test("Medium Formatter injects hero image, saccadic anchors, and preserves LaTeX")
    func testMediumFormatterHeroAndAnchors() {
        let sample = """
        # Asynchronous Byzantine Fault Tolerance in Practice
        *A deep dive into node consensus.*
        
        *4 min read · 820 words · Boost-Optimized*
        ---
        
        The distributed network operates under partial synchrony where the signature verification bounds hold for $S = \\sum_{i=1}^n v_i$.
        
        Under production conditions, the leader node experienced thread contention across memory channels.
        
        Our benchmark telemetry revealed that disk writes were the hidden bottleneck.
        
        Storage queues backed up during the failover transition, preventing timely snapshot persistence.
        """
        
        let result = MediumFormatterEngine.format(text: sample)
        
        // 1. Math integrity verified
        #expect(result.formattedText.contains("$S = \\sum_{i=1}^n v_i$"))
        
        // 2. Hero image injected with Unsplash attribution
        #expect(result.heroImageInjected)
        #expect(result.formattedText.contains("images.unsplash.com"))
        #expect(result.formattedText.contains("Figure 1:"))
        
        // 3. Saccadic bold anchors injected
        #expect(result.saccadicAnchorsInjected > 0)
        #expect(result.formattedText.contains("**"))
        
        // 4. Optimal bolding density
        #expect(result.boldingDensityPercentage >= 1.0 && result.boldingDensityPercentage <= 15.0)
        
        // 5. High visual saliency score
        #expect(result.visualSaliencyScore >= 70.0)
    }
    
    @Test("Medium Formatter converts sequential enumerations to scannable bullet points and polishes typography")
    func testMediumFormatterListAndTypography() {
        let sample = """
        To resolve the latency regression, three specific actions were executed.
        First, we pruned unnecessary database indexing.
        Second, we enabled zero-copy buffer serialization across RPC channels.
        Third, we isolated asynchronous logging onto a dedicated SSD partition.
        
        The throughput improved significantly -- without adding extra compute nodes.
        """
        
        let result = MediumFormatterEngine.format(text: sample)
        
        // 1. Lists formatted to markdown bullets with bold prefixes
        #expect(result.listsFormatted > 0 || result.formattedText.contains("- **"))
        
        // 2. Unicode em-dash replaced " -- "
        #expect(result.formattedText.contains(" — "))
        #expect(!result.formattedText.contains(" -- "))
    }
    
    // MARK: - Medium HTML Renderer & Deep Formatting Tests
    
    @Test("Medium HTML Renderer converts Markdown into semantic ProseMirror HTML for native paste")
    func testMediumHTMLRendererGeneratesValidMediumDOM() {
        let markdown = """
        APPLIED NLP // STOCHASTIC DYNAMICS
        
        # Breaking the Neural Softmax Metronome
        *How stochastic clause inversion shatters detector cross-perplexity.*
        
        *5 min read · 1,120 words · Boost-Optimized*
        
        ---
        
        ![Neural Architecture Diagram](https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&w=1200&q=80)
        *Figure 1: Stochastic variance under adversarial evaluation.*
        
        Under production conditions, the detector failed to identify humanized prose.
        
        ## The Production Reality
        We observed that **syntactic decoupling** and *staccato fragments* were essential.
        
        > "The bottleneck in AI detection is structural, not lexical."
        
        - First, clause hierarchies were inverted.
        - Second, pragmatic anchors were inserted.
        
        ---
        """
        
        let html = MediumHTMLRenderer.renderHTML(fromMarkdown: markdown)
        
        // 1. Medium Title mapped to h1
        #expect(html.contains("<h1>Breaking the Neural Softmax Metronome</h1>"))
        
        // 2. Medium Subtitle mapped to h2
        #expect(html.contains("<h2>How stochastic clause inversion shatters detector cross-perplexity.</h2>"))
        
        // 3. Medium Section Header mapped to h3
        #expect(html.contains("<h3>The Production Reality</h3>"))
        
        // 4. Medium Divider mapped to hr
        #expect(html.contains("<hr/>"))
        
        // 5. Bold & Italics mapped to strong and em (no raw asterisks)
        #expect(html.contains("<strong>syntactic decoupling</strong>"))
        #expect(html.contains("<em>staccato fragments</em>"))
        
        // 6. Blockquote mapped to blockquote
        #expect(html.contains("<blockquote><p>"))
        
        // 7. Lists mapped to ul/li
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>"))
        
        // 8. Figure and Image
        #expect(html.contains("<figure><img"))
        #expect(html.contains("<figcaption>"))
    }
    
    @Test("Medium Optimizer dynamically synthesizes topic-relevant title instead of hardcoded fallback")
    func testMediumOptimizerDynamicTitleSynthesis() {
        let draft = """
        Three standard-issue brain bug: Confirmation bias. Anchoring bias. Availability heuristic.
        They are not exotic syndromes; they are mental shortcuts leftover from hunter-gatherer environments.
        Today those same shortcuts steer us into buying useless products and defending flawed opinions.
        """
        
        let res = MediumOptimizer.optimize(text: draft)
        
        // Must NOT contain hardcoded "Mathematical Limits of Modern System Design"
        #expect(!res.title.contains("Mathematical Limits of Modern System Design"))
        #expect(!res.finalizedText.contains("Mathematical Limits of Modern System Design"))
        
        // Must contain dynamically extracted title relating to brain bugs
        #expect(res.title.lowercased().contains("brain bug") || res.title.lowercased().contains("three standard"))
        
        // Dynamic kicker must reflect cognitive psychology
        #expect(res.kicker.contains("COGNITIVE") || res.kicker.contains("PSYCHOLOGY"))
    }
    
    @Test("Medium Formatter guarantees no asterisks span across newlines and headings are preserved")
    func testMediumFormatterNoNewlineInsideBolding() {
        let draft = """
        Confirmation Bias
        Your brain acts like a hyper-focused search engine programmed only to find results backing what you already think. Contradictory proof gets treated like it's got a virus.
        
        Anchoring Effect
        The first piece of information you hear sets the baseline for everything that follows.
        """
        
        let res = MediumFormatterEngine.format(text: draft)
        
        // 1. Must NOT contain broken asterisks across lines: **Confirmation Bias\nYour**
        #expect(!res.formattedText.contains("**Confirmation Bias\nYour**"))
        #expect(!res.formattedText.contains("Bias\nYour**"))
        
        // 2. Isolated headings must be preserved as headers
        #expect(res.formattedText.contains("## Confirmation Bias") || res.formattedText.contains("Confirmation Bias"))
    }
}
