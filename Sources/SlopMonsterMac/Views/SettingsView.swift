import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    
    @State private var connectionStatus: String = ""
    @State private var isTesting: Bool = false
    @State private var selectedCategory: ModelCategory = .local
    @State private var availableOllamaModels: [String] = []
    @State private var showingSampleSheet: Bool = false
    @State private var authorSampleInput: String = ""
    @State private var authorStatusMessage: String = ""
    
    public init() {}
    
    public var body: some View {
        Form {
            // Category Segmented Control
            Section("MODEL ECOSYSTEM & ACCESS") {
                Picker("Provider Category", selection: $selectedCategory) {
                    ForEach(ModelCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)
                
                // Provider Picker within Category
                Picker("Active Engine", selection: $settings.cleanseProvider) {
                    ForEach(CleanseProviderType.allCases.filter { $0.category == selectedCategory }) { p in
                        Label(p.rawValue, systemImage: p.icon).tag(p)
                    }
                }
                .onChange(of: selectedCategory) { _, newCat in
                    if let first = CleanseProviderType.allCases.first(where: { $0.category == newCat }) {
                        settings.cleanseProvider = first
                    }
                }
            }
            
            // Active Provider Credentials & Setup
            Section("CONFIGURATION: \(settings.cleanseProvider.rawValue.uppercased())") {
                // Base URL
                LabeledContent("Endpoint URL") {
                    switch settings.cleanseProvider {
                    case .localOllama:
                        TextField("", text: $settings.ollamaHost)
                            .textFieldStyle(.roundedBorder)
                    case .localLMStudio:
                        TextField("", text: $settings.lmStudioHost)
                            .textFieldStyle(.roundedBorder)
                    case .localMLX:
                        TextField("", text: $settings.mlxHost)
                            .textFieldStyle(.roundedBorder)
                    case .localCustom:
                        TextField("", text: $settings.localCustomHost)
                            .textFieldStyle(.roundedBorder)
                    case .customOpenAI:
                        TextField("", text: $settings.customApiUrl)
                            .textFieldStyle(.roundedBorder)
                    case .nvidiaNIM:
                        TextField("", text: $settings.nvidiaBaseURL)
                            .textFieldStyle(.roundedBorder)
                    default:
                        Text(settings.cleanseProvider.defaultBaseURL)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // API Key if required
                if settings.cleanseProvider.requiresAPIKey {
                    LabeledContent("API Key") {
                        switch settings.cleanseProvider {
                        case .claude:
                            SecureField("", text: $settings.claudeApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .openAI:
                            SecureField("", text: $settings.openAIApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .openRouter:
                            SecureField("", text: $settings.openRouterApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .gemini:
                            SecureField("", text: $settings.geminiApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .deepSeek:
                            SecureField("", text: $settings.deepSeekApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .groq:
                            SecureField("", text: $settings.groqApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .mistral:
                            SecureField("", text: $settings.mistralApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .xAI:
                            SecureField("", text: $settings.xAiApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .nvidiaNIM:
                            SecureField("", text: $settings.nvidiaApiKey)
                                .textFieldStyle(.roundedBorder)
                        case .customOpenAI:
                            SecureField("", text: $settings.customApiKey)
                                .textFieldStyle(.roundedBorder)
                        default:
                            EmptyView()
                        }
                    }
                    Text("Saved securely in local macOS preferences. Direct HTTPS calls; no intermediary server.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                // Model Selection
                LabeledContent("Model Name") {
                    switch settings.cleanseProvider {
                    case .localOllama:
                        TextField("", text: $settings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                    case .localLMStudio:
                        TextField("", text: $settings.lmStudioModel)
                            .textFieldStyle(.roundedBorder)
                    case .localMLX:
                        TextField("", text: $settings.mlxModel)
                            .textFieldStyle(.roundedBorder)
                    case .localCustom:
                        TextField("", text: $settings.localCustomModel)
                            .textFieldStyle(.roundedBorder)
                    case .claude:
                        TextField("", text: $settings.claudeModel)
                            .textFieldStyle(.roundedBorder)
                    case .openAI:
                        TextField("", text: $settings.openAIModel)
                            .textFieldStyle(.roundedBorder)
                    case .openRouter:
                        TextField("", text: $settings.openRouterModel)
                            .textFieldStyle(.roundedBorder)
                    case .gemini:
                        TextField("", text: $settings.geminiModel)
                            .textFieldStyle(.roundedBorder)
                    case .deepSeek:
                        TextField("", text: $settings.deepSeekModel)
                            .textFieldStyle(.roundedBorder)
                    case .groq:
                        TextField("", text: $settings.groqModel)
                            .textFieldStyle(.roundedBorder)
                    case .mistral:
                        TextField("", text: $settings.mistralModel)
                            .textFieldStyle(.roundedBorder)
                    case .xAI:
                        TextField("", text: $settings.xAiModel)
                            .textFieldStyle(.roundedBorder)
                    case .nvidiaNIM:
                        TextField("", text: $settings.nvidiaModel)
                            .textFieldStyle(.roundedBorder)
                    case .customOpenAI:
                        TextField("", text: $settings.customModel)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Suggested Presets
                if !settings.cleanseProvider.suggestedModels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            Text("Presets:")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            ForEach(settings.cleanseProvider.suggestedModels, id: \.self) { m in
                                Button(m) {
                                    applyPresetModel(m)
                                }
                                .buttonStyle(.borderless)
                                .font(.system(size: 9, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(3)
                            }
                        }
                    }
                }
                
                // Test Connection
                HStack {
                    Button(action: testActiveConnection) {
                        HStack(spacing: 4) {
                            if isTesting {
                                ProgressView().scaleEffect(0.6)
                            } else {
                                Image(systemName: "network")
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(isTesting)
                    
                    Spacer()
                    
                    if !connectionStatus.isEmpty {
                        Text(connectionStatus)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(connectionStatus.contains("verified") || connectionStatus.contains("online") || connectionStatus.contains("successful") ? .green : .red)
                            .lineLimit(1)
                    }
                }
                
                // Special guidance for Apple MLX
                if settings.cleanseProvider == .localMLX {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("💡 What is Apple MLX?")
                            .font(.system(size: 11, weight: .bold))
                        Text("Apple MLX runs open-weight models directly on Apple Silicon GPU/Unified Memory with zero CPU overhead. To run a local server in Terminal:")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("python3 -m mlx_lm.server --model mlx-community/Llama-3.2-3B-Instruct")
                                .font(.system(size: 9, design: .monospaced))
                                .padding(4)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(3)
                            
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("python3 -m mlx_lm.server --model mlx-community/Llama-3.2-3B-Instruct", forType: .string)
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 10))
                        }
                    }
                    .padding(8)
                    .background(Color.accentColor.opacity(0.08))
                    .cornerRadius(6)
                }
                
                // Special guidance for NVIDIA NIM
                if settings.cleanseProvider == .nvidiaNIM {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🚀 NVIDIA NIM & Nemotron Models")
                            .font(.system(size: 11, weight: .bold))
                        Text("NVIDIA NIM runs ultra-high precision models like Llama 3.1 Nemotron 70B Ultra and Nemotron Mini 4B. Get free API credits and keys directly at build.nvidia.com.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Endpoint: https://integrate.api.nvidia.com/v1")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Copy URL") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("https://integrate.api.nvidia.com/v1", forType: .string)
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 10))
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(6)
                }
            }
            
            Section("AUTHOR STYLOMETRIC FINGERPRINT (FRONTIER 4: KL-DIVERGENCE)") {
                if let profile = settings.authorProfile {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundColor(.green)
                            Text("Active Profile: \(profile.sampleWordCount) words, \(profile.sampleSentenceCount) sentences")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                            Spacer()
                            Button("Clear Profile") {
                                settings.clearAuthorProfile()
                                authorStatusMessage = "Profile removed"
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cadence: \(String(format: "%.1f", profile.sentenceLengthMean)) ± \(String(format: "%.1f", profile.sentenceLengthStdDev)) w/sent")
                                    .font(.system(size: 10, design: .monospaced))
                                Text("TTR: \(String(format: "%.2f", profile.typeTokenRatio)) | Hapax: \(Int(profile.hapaxRatio * 100))%")
                                    .font(.system(size: 10, design: .monospaced))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Commas: \(String(format: "%.1f", profile.commaRate))/100w")
                                    .font(.system(size: 10, design: .monospaced))
                                Text("Contractions: \(Int(profile.contractionRate * 100))%")
                                    .font(.system(size: 10, design: .monospaced))
                            }
                        }
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Replace with Clipboard Sample") {
                                importSampleFromClipboard()
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                            
                            Button("Paste New Sample...") {
                                showingSampleSheet = true
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                        }
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.06))
                    .cornerRadius(6)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No author stylometric profile active.")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Provide a 100+ word writing sample of your authentic writing. SlopMonster will extract your personal sentence cadence, punctuation habits, and vocabulary richness to guide KL-divergence minimization.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Button("Paste Sample from Clipboard") {
                                importSampleFromClipboard()
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.system(size: 10))
                            
                            Button("Paste Manually...") {
                                showingSampleSheet = true
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                        }
                        
                        if !authorStatusMessage.isEmpty {
                            Text(authorStatusMessage)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(authorStatusMessage.contains("Extracted") ? .green : .red)
                        }
                    }
                }
            }
            
            Section("LINTER SENSITIVITY") {
                Toggle("Allow Unverified Proof (Ignore penalty for customer counts)", isOn: $settings.allowProofPenalty)
                TextField("Default Copy Register Context", text: $settings.writingContext)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section("RETRO MAC OS AESTHETICS") {
                Toggle("Sound Effects (Mechanical typewriter & classic chimes)", isOn: $settings.enableSoundEffects)
                Toggle("Subtle CRT Phosphor Scanlines Effect", isOn: $settings.enableCRTOverlay)
            }
            
            Section("ABOUT SLOPMONSTER") {
                HStack(spacing: 12) {
                    PixelMonsterView(state: .clean, size: 36, tint: .green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SlopMonster for macOS v3.0 (OVERKILL & Medium Boost Edition)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text("Deterministic Humanizer, 8 Stochastic Frontiers (Hurst, Fano, Benford, Heaps, Author KL), 14+ Rival LLMs, and 1-Click Medium Publication Engine.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 580, height: 560)
        .onAppear {
            selectedCategory = settings.cleanseProvider.category
        }
        .sheet(isPresented: $showingSampleSheet) {
            VStack(alignment: .leading, spacing: 12) {
                Text("PASTE YOUR AUTHENTIC WRITING SAMPLE")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                Text("Paste 100+ words of genuine writing you wrote yourself (an email, essay, blog post, or article). SlopMonster will extract your personal stylometric fingerprint to minimize KL-divergence.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $authorSampleInput)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(minHeight: 180)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                
                HStack {
                    Button("Cancel") {
                        showingSampleSheet = false
                    }
                    Spacer()
                    Button("Analyze & Save Fingerprint") {
                        processSample(authorSampleInput)
                        showingSampleSheet = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(authorSampleInput.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).count < 50)
                }
            }
            .padding(16)
            .frame(width: 520, height: 360)
        }
    }
    
    private func importSampleFromClipboard() {
        if let clip = NSPasteboard.general.string(forType: .string), !clip.isEmpty {
            processSample(clip)
        } else {
            authorStatusMessage = "Clipboard is empty"
        }
    }
    
    private func processSample(_ text: String) {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard words.count >= 60 else {
            authorStatusMessage = "Sample too short (\(words.count) words). Need ≥60 words."
            return
        }
        let profile = AuthorProfileEngine.extractProfile(from: text)
        settings.saveAuthorProfile(profile)
        authorStatusMessage = "Extracted profile from \(profile.sampleWordCount) words (\(profile.sampleSentenceCount) sentences)!"
        RetroSound.playCleanChime()
    }
    
    private func applyPresetModel(_ model: String) {
        switch settings.cleanseProvider {
        case .localOllama: settings.ollamaModel = model
        case .localLMStudio: settings.lmStudioModel = model
        case .localMLX: settings.mlxModel = model
        case .localCustom: settings.localCustomModel = model
        case .claude: settings.claudeModel = model
        case .openAI: settings.openAIModel = model
        case .openRouter: settings.openRouterModel = model
        case .gemini: settings.geminiModel = model
        case .deepSeek: settings.deepSeekModel = model
        case .groq: settings.groqModel = model
        case .mistral: settings.mistralModel = model
        case .xAI: settings.xAiModel = model
        case .nvidiaNIM: settings.nvidiaModel = model
        case .customOpenAI: settings.customModel = model
        }
    }
    
    private func testActiveConnection() {
        isTesting = true
        connectionStatus = ""
        let creds = settings.activeCredentials()
        
        Task {
            let res = await CleanseService.shared.testConnection(
                provider: settings.cleanseProvider,
                baseURL: creds.baseURL,
                apiKey: creds.apiKey,
                model: creds.model
            )
            await MainActor.run {
                self.connectionStatus = res.message
                self.isTesting = false
            }
        }
    }
}
