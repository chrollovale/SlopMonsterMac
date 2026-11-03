import SwiftUI
import AppKit

public enum WorkspaceTab: String, CaseIterable, Identifiable {
    case studio = "Studio"
    case diagnostics = "Diagnostics"
    case diff = "Diff"
    case batch = "Batch Scanner"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .studio: return "square.split.2x1"
        case .diagnostics: return "stethoscope"
        case .diff: return "arrow.left.arrow.right"
        case .batch: return "folder"
        }
    }
}

public struct MainWindowView: View {
    @ObservedObject var settings = AppSettings.shared
    
    @State private var selectedTab: WorkspaceTab = .studio
    @State private var draftText: String = ""
    @State private var cleansedText: String = ""
    @State private var changeNotes: [String] = []
    @State private var report: SlopReport = SlopReport.empty
    @State private var isCleansing: Bool = false
    @State private var lastCleanseDuration: Double = 0.0
    @State private var lastProviderUsed: String = ""
    @State private var errorMessage: String? = nil
    @State private var showingSettings: Bool = false
    @State private var zeroExpansionMode: Bool = false
    @State private var enablePerplexitySpikes: Bool = false
    @State private var isOverkilling: Bool = false
    @State private var isMediumGenerating: Bool = false
    @State private var copyFeedbackMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Retro Status & Navigation Bar
            HStack(spacing: 12) {
                // Retro App Brand
                HStack(spacing: 6) {
                    PixelMonsterView(
                        state: isCleansing ? .cleansing : (report.classicScore == 5 ? .clean : (report.classicScore > 2 ? .suspicious : .alarmed)),
                        size: 26,
                        tint: report.classicScore == 5 ? .green : (report.classicScore > 2 ? .orange : .red)
                    )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SLOPMONSTER")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                        Text("MAC OS NATIVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider().frame(height: 20)
                
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    ForEach(WorkspaceTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
                
                Spacer()
                
                // Classic Stamp & Slop Density Meter
                SlopDensityMeterView(sdi: report.slopDensityIndex)
                RetroStampView(score: report.classicScore)
                
                Divider().frame(height: 20)
                
                // Cleanse Provider Quick Picker
                Picker("", selection: $settings.cleanseProvider) {
                    ForEach(CleanseProviderType.allCases) { p in
                        Text(p.shortName).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                // Settings button
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape")
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main Content Area
            ZStack {
                switch selectedTab {
                case .studio:
                    studioSplitView
                case .diagnostics:
                    DiagnosticsView(report: report)
                case .diff:
                    DiffView(original: draftText, revised: cleansedText)
                case .batch:
                    BatchScannerView()
                }
                
                // Subtle CRT Scanline overlay if enabled
                if settings.enableCRTOverlay {
                    CRTScanlineOverlay()
                        .allowsHitTesting(false)
                }
            }
            
            Divider()
            
            // Bottom Action & Diagnostics Pill Bar
            bottomBarView
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            if draftText.isEmpty {
                loadSampleDraft()
            }
        }
    }
    
    // MARK: - Studio Split View
    private var studioSplitView: some View {
        HSplitView {
            // Left: Draft Input
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("DRAFT INPUT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    if report.watermarkCount > 0 {
                        Button(action: purgeWatermarks) {
                            HStack(spacing: 3) {
                                Image(systemName: "shield.slash.fill")
                                Text("Purge \(report.watermarkCount) Watermarks")
                            }
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.2))
                            .foregroundColor(.cyan)
                            .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Button("Load AI Sample") {
                        loadSampleDraft()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 10, design: .monospaced))
                    
                    Text("·")
                    
                    Button("Clear") {
                        draftText = ""
                        updateAudit()
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 10, design: .monospaced))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                
                Divider()
                
                TextEditor(text: $draftText)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(8)
                    .onChange(of: draftText) { _, newText in
                        updateAudit()
                        RetroSound.playTypeSound()
                    }
            }
            .frame(minWidth: 400)
            
            // Right: Cleansed Output
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Text("CLEANSED COPY (RIVAL PASS)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        if !lastProviderUsed.isEmpty {
                            Text("[\(lastProviderUsed)]")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Spacer()
                    
                    if !cleansedText.isEmpty {
                        // 1. Dedicated Copy for Medium button
                        Button(action: copyForMedium) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.clipboard.fill")
                                Text("Copy for Medium")
                            }
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.05, green: 0.65, blue: 0.35).opacity(0.15))
                            .foregroundColor(Color(red: 0.05, green: 0.65, blue: 0.35))
                            .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                        .help("Copies Native Medium Rich Text (HTML) to clipboard. Pressing ⌘V in Medium will render native Title, Subtitle, Dividers, Headings, and Bold formatting!")
                        
                        Text("·")
                        
                        Button("Format 📐") {
                            triggerFormat()
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .help("Format current cleansed text with eye-tracking saccadic anchors and Medium typography")
                        
                        Text("·")
                        
                        Button("Copy ⌘⇧C") {
                            copyForMedium()
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        
                        Text("·")
                        
                        Button("Use as Draft") {
                            draftText = cleansedText
                            updateAudit()
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, design: .monospaced))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                
                if let msg = copyFeedbackMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                        Text(msg)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .transition(.opacity)
                }
                
                Divider()
                
                if isCleansing {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        PixelMonsterView(
                            state: .cleansing,
                            size: 48,
                            tint: isMediumGenerating ? Color(red: 0.05, green: 0.65, blue: 0.35) : (isOverkilling ? .purple : .accentColor)
                        )
                        Text(isMediumGenerating ? "📝 MEDIUM: Fusing OVERKILL Evasion + Attention Dynamics + Mobile Pacing..." : (isOverkilling ? "💥 OVERKILL: Fusing AI Cleanse, 8 Stochastic Frontiers & Math Audits..." : "Rival model purging AI tells and clichéd cadences..."))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(isMediumGenerating ? Color(red: 0.05, green: 0.65, blue: 0.35) : (isOverkilling ? .purple : .secondary))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !cleansedText.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        TextEditor(text: $cleansedText)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(8)
                        
                        // Change Notes Drawer
                        if !changeNotes.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SUBSTANTIVE EDITS & NOTES:")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                ForEach(changeNotes.prefix(4), id: \.self) { note in
                                    Text("• \(note)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        PixelMonsterView(state: .clean, size: 48, tint: .secondary.opacity(0.5))
                        Text("Click 'Cleanse Draft ⌘⏎' to run rival model pass.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBarView: some View {
        HStack(spacing: 12) {
            // Metrics summary
            HStack(spacing: 10) {
                Text("\(report.wordCount) words")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(report.sentenceCount) sentences")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("~\(report.estimatedReadingTimeSeconds)s read")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                if report.wordCount >= 20 {
                    Text("Entropy: \(String(format: "%.0f%%", report.entropyResult.entropyPercentage))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(report.entropyResult.entropyPercentage >= 65 ? .green : (report.entropyResult.entropyPercentage >= 45 ? .orange : .red))
                        .help(report.entropyResult.assessment)
                }
                
                if report.wordCount >= 40 {
                    Text("Zipf α: \(String(format: "%.2f", report.zipfianMetrics.alphaSlope))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(report.zipfianMetrics.isZipfianCompliant ? .secondary : .orange)
                        .help(report.zipfianMetrics.assessment)
                }
                
                if report.wordCount >= 300 {
                    Text("Macro: \(Int(report.macroResilienceScore))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(report.macroResilienceScore >= 80 ? .green : (report.macroResilienceScore >= 60 ? .orange : .red))
                        .help("Macro Evasion Resilience for Long Documents: Evaluates paragraph asymmetry, discourse entropy, and winnowing n-gram risk.")
                }
                
                if report.wordCount >= 100 {
                    Text("Hurst H: \(String(format: "%.2f", report.hurstMetrics.hurstExponent))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(report.hurstMetrics.hasLongRangeMemory ? .secondary : .orange)
                        .help(report.hurstMetrics.assessment)
                }
                
                if settings.authorProfile != nil && report.wordCount >= 50 {
                    Text("Author: \(Int(report.stylometricMatch.matchPercentage))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(report.stylometricMatch.matchPercentage >= 80 ? .green : (report.stylometricMatch.matchPercentage >= 65 ? .orange : .red))
                        .help(report.stylometricMatch.assessment)
                }
            }
            
            Divider().frame(height: 16)
            
            // Live Hits Scroll
            if !report.hits.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(report.hits.prefix(6)) { hit in
                            Button(action: { selectedTab = .diagnostics }) {
                                HStack(spacing: 3) {
                                    Text(hit.category.retroBadge)
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    Text(hit.label)
                                        .font(.system(size: 9, design: .monospaced))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(3)
                            }
                            .buttonStyle(.plain)
                        }
                        if report.hits.count > 6 {
                            Text("+\(report.hits.count - 6) more")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("Prose is 100% clean of detected AI tells.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
            
            Button("Paste Clipboard") {
                if let clip = NSPasteboard.general.string(forType: .string) {
                    draftText = clip
                    updateAudit()
                }
            }
            .font(.system(size: 11))
            
            // Turnitout Zero-AI 1:1 Parity Mode Toggle
            Toggle("1:1 Word Parity", isOn: $zeroExpansionMode)
                .toggleStyle(.checkbox)
                .font(.system(size: 10, design: .monospaced))
                .help("Turnitout Zero-Expansion Mode: Restrict modifications to exact 1-to-1 word replacements without adding new tokens.")
            
            // Tier-3 Adversarial Perplexity Spike Injection Toggle
            Toggle("⚡ Perplexity Spikes", isOn: $enablePerplexitySpikes)
                .toggleStyle(.checkbox)
                .font(.system(size: 10, design: .monospaced))
                .help("Inject adversarial perplexity waveform spikes (rare academic synonyms) to defeat DetectGPT flat-curvature analysis.")
            
            // Fast Zero-AI Deterministic Humanize (Turnitout Rule Engine)
            Button(action: triggerDeterministicHumanize) {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                    Text("Zero-AI Fast")
                }
            }
            .buttonStyle(.bordered)
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCleansing)
            .help("Run 100% offline, zero-hallucination deterministic humanizer and watermark purge.")
            
            Button(action: triggerCleanse) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("Cleanse Draft ⌘⏎")
                }
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCleansing)
            
            // 💥 THE OVERKILL BUTTON (Combines AI Cleanse + Mathematical Humanizer + Edge-Case Verification)
            Button(action: triggerOverkill) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("💥 OVERKILL")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.purple)
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCleansing)
            .help("THE OVERKILL: Fuses Rival AI Cleanse + Deterministic Humanizer + All 8 Mathematical Frontiers (Zipf, Yngve, Hurst, Fano, Benford, Heaps, Author KL) + Edge-Case Verification Loop for the absolute cleanest version.")
            
            // 📝 THE MEDIUM BUTTON (Runs Overkill Pipeline + Medium Mathematical Attention/Retention Optimization)
            Button(action: triggerMedium) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                    Text("📝 MEDIUM")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.05, green: 0.65, blue: 0.35))
            .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCleansing)
            .help("MEDIUM PRODUCTION: Fuses OVERKILL evasion with mathematical attention models (Loewenstein information gaps, 30s hooks, 1-3 sentence mobile pacing, H2 meso loops, pull quotes, and community discussion anchors) for 1-click publication.")
            
            // 📐 THE FORMATTER BUTTON (Applies Saccadic Anchor Bolding, F-Pattern Optimization, Hero Images & Typographic Polish)
            Button(action: triggerFormat) {
                HStack(spacing: 4) {
                    Image(systemName: "text.alignleft")
                    Text("📐 FORMAT")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            .disabled((cleansedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || isCleansing)
            .help("FORMATTER ENGINE: Mathematically optimizes text for maximum reader retention and scanning via Rayner saccadic anchors, F-pattern bolding distribution (2-4%), Unsplash hero imagery, list normalization, and typographic em-dash polishing.")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Logic
    private func updateAudit() {
        report = SlopEngine.shared.audit(text: draftText, isMarkdown: true, allowProof: settings.allowProofPenalty, authorProfile: settings.authorProfile)
    }
    
    private func purgeWatermarks() {
        let res = TextNormalizer.purgeZeroWidthUnicode(draftText)
        draftText = res.cleaned
        updateAudit()
        RetroSound.playCleanChime()
    }
    
    private func triggerDeterministicHumanize() {
        guard !draftText.isEmpty else { return }
        let res = DeterministicHumanizer.humanize(
            text: draftText,
            zeroExpansion: zeroExpansionMode,
            adversarialSpikes: enablePerplexitySpikes,
            authorProfile: settings.authorProfile
        )
        self.cleansedText = res.transformedText
        self.changeNotes = res.editsApplied
        let spikeSuffix = enablePerplexitySpikes ? " + Perplexity Spikes" : ""
        self.lastProviderUsed = (zeroExpansionMode ? "Turnitout 1:1 Parity Mode" : "Turnitout Zero-AI Engine") + spikeSuffix
        self.lastCleanseDuration = 0.001
        RetroSound.playCleanChime()
    }
    
    private func triggerCleanse() {
        guard !draftText.isEmpty else { return }
        isCleansing = true
        errorMessage = nil
        
        Task {
            let creds = settings.activeCredentials()
            do {
                let res = try await CleanseService.shared.cleanse(
                    draft: draftText,
                    provider: settings.cleanseProvider,
                    baseURL: creds.baseURL,
                    apiKey: creds.apiKey,
                    model: creds.model,
                    context: settings.writingContext
                )
                
                await MainActor.run {
                    self.cleansedText = res.cleansedText
                    self.changeNotes = res.changeNotes
                    self.lastProviderUsed = res.providerName
                    self.lastCleanseDuration = res.durationSeconds
                    self.isCleansing = false
                    RetroSound.playCleanChime()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isCleansing = false
                }
            }
        }
    }
    
    private func triggerOverkill() {
        guard !draftText.isEmpty else { return }
        isCleansing = true
        isOverkilling = true
        errorMessage = nil
        
        Task {
            let creds = settings.activeCredentials()
            let res = await OverkillEngine.execute(
                draft: draftText,
                provider: settings.cleanseProvider,
                baseURL: creds.baseURL,
                apiKey: creds.apiKey,
                model: creds.model,
                context: settings.writingContext,
                authorProfile: settings.authorProfile,
                zeroExpansion: zeroExpansionMode
            )
            
            await MainActor.run {
                self.cleansedText = res.finalizedText
                self.changeNotes = res.changeNotes
                self.lastProviderUsed = "💥 OVERKILL [\(res.providerUsed)]"
                self.lastCleanseDuration = res.durationSeconds
                self.isCleansing = false
                self.isOverkilling = false
                RetroSound.playCleanChime()
            }
        }
    }
    
    private func triggerMedium() {
        guard !draftText.isEmpty else { return }
        isCleansing = true
        isMediumGenerating = true
        errorMessage = nil
        
        Task {
            let creds = settings.activeCredentials()
            // Step 1: Run the full 10-pass OVERKILL pipeline (purges tells, masks math, runs DIPPER/Binoculars)
            let overkillRes = await OverkillEngine.execute(
                draft: draftText,
                provider: settings.cleanseProvider,
                baseURL: creds.baseURL,
                apiKey: creds.apiKey,
                model: creds.model,
                context: settings.writingContext,
                authorProfile: settings.authorProfile,
                zeroExpansion: zeroExpansionMode
            )
            
            // Step 2: Apply the Medium Mathematical Retention & Attention Optimizer
            let mediumRes = MediumOptimizer.optimize(
                text: overkillRes.finalizedText,
                authorProfile: settings.authorProfile
            )
            
            await MainActor.run {
                self.cleansedText = mediumRes.finalizedText
                var notes = overkillRes.changeNotes
                notes.append(contentsOf: mediumRes.transformationsApplied)
                notes.append("Medium Telemetry: \(mediumRes.wordCount) words · \(mediumRes.estimatedReadMinutes) min read · Predicted Read Ratio: \(Int(mediumRes.predictedReadRatio))%")
                self.changeNotes = notes
                self.lastProviderUsed = "📝 MEDIUM [OVERKILL + Boost Retention Engine]"
                self.lastCleanseDuration = overkillRes.durationSeconds
                self.isCleansing = false
                self.isMediumGenerating = false
                RetroSound.playCleanChime()
            }
        }
    }
    
    private func triggerFormat() {
        let sourceText = cleansedText.isEmpty ? draftText : cleansedText
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let formatResult = MediumFormatterEngine.format(text: sourceText)
        
        cleansedText = formatResult.formattedText
        var notes = changeNotes
        notes.append(contentsOf: formatResult.transformationsApplied)
        notes.append("Formatting Telemetry: Bolding Density: \(String(format: "%.1f", formatResult.boldingDensityPercentage))% · Saccadic Anchors: \(formatResult.saccadicAnchorsInjected) · Visual Saliency Score: \(Int(formatResult.visualSaliencyScore))%")
        changeNotes = notes
        lastProviderUsed = "📐 FORMATTER [Rayner Saccadic + F-Pattern]"
        RetroSound.playCleanChime()
    }
    
    private func copyForMedium() {
        guard !cleansedText.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 1. Render semantic Medium-compatible rich HTML (h1 Title, h2 Subtitle, h3 Headers, hr Dividers, strong Bold, em Italics)
        let richHTML = MediumHTMLRenderer.renderHTML(fromMarkdown: cleansedText)
        if let htmlData = richHTML.data(using: .utf8) {
            pasteboard.setData(htmlData, forType: .html)
        }
        
        // 2. Also write standard clean Markdown as plain text fallback
        pasteboard.setString(cleansedText, forType: .string)
        
        copyFeedbackMessage = "✓ Copied Native Medium Format! Press ⌘V in Medium to render Title, Subtitle, & Dividers."
        RetroSound.playCleanChime()
        
        // Clear message after 4.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            if self.copyFeedbackMessage?.contains("Medium") == true {
                self.copyFeedbackMessage = nil
            }
        }
    }
    
    private func loadSampleDraft() {
        draftText = """
        # Ridgeline Roofing Platform

        Our cutting-edge platform seamlessly elevates your roofing workflow.
        Whether you are a homeowner or a commercial contractor, that's where Ridgeline comes in.
        
        It is not just a roof, it is a game-changing journey into peace of mind.
        We leverage industry-leading materials to foster robust synergy across projects.
        
        Trusted by 10,000+ happy homeowners, our solution is faster, smarter, and better.
        At the end of the day, say goodbye to leaks — our factory-trained, context-aware,
        next-level team is ready to get started.
        """
        updateAudit()
    }
}

// Subtle CRT scanline effect
struct CRTScanlineOverlay: View {
    var body: some View {
        Canvas { context, size in
            let scanlineSpacing: CGFloat = 3.0
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(rect), with: .color(Color.black.opacity(0.04)))
                y += scanlineSpacing
            }
        }
    }
}
