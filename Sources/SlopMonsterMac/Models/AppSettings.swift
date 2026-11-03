import Foundation
import SwiftUI
import Combine

public enum ModelCategory: String, CaseIterable, Identifiable, Sendable {
    case local = "Local & On-Device (Free / Private)"
    case cloud = "Cloud AI Providers"
    case custom = "Universal / Custom OpenAPI"
    
    public var id: String { rawValue }
}

public enum CleanseProviderType: String, CaseIterable, Identifiable, Codable, Sendable {
    // Local / On-Device
    case localOllama = "Local Ollama"
    case localLMStudio = "LM Studio (Local)"
    case localMLX = "Apple MLX Local Engine"
    case localCustom = "Custom Localhost Endpoint"
    
    // Cloud Providers
    case openRouter = "OpenRouter (200+ Models)"
    case claude = "Anthropic Claude 3.5"
    case openAI = "OpenAI (GPT-4o / o1 / o3)"
    case gemini = "Google Gemini"
    case deepSeek = "DeepSeek (V3 / R1)"
    case groq = "Groq (Ultra-Fast Llama 3.3)"
    case mistral = "Mistral AI"
    case xAI = "xAI (Grok 2)"
    case nvidiaNIM = "NVIDIA NIM (Nemotron & Llama)"
    case customOpenAI = "Custom OpenAI-Compatible API"
    
    public var id: String { rawValue }
    
    public var category: ModelCategory {
        switch self {
        case .localOllama, .localLMStudio, .localMLX, .localCustom:
            return .local
        case .claude, .openAI, .gemini, .deepSeek, .groq, .mistral, .xAI, .nvidiaNIM:
            return .cloud
        case .openRouter, .customOpenAI:
            return .custom
        }
    }
    
    public var shortName: String {
        switch self {
        case .localOllama: return "Ollama"
        case .localLMStudio: return "LM Studio"
        case .localMLX: return "Apple MLX"
        case .localCustom: return "Localhost"
        case .openRouter: return "OpenRouter"
        case .claude: return "Claude 3.5"
        case .openAI: return "OpenAI"
        case .gemini: return "Gemini"
        case .deepSeek: return "DeepSeek"
        case .groq: return "Groq"
        case .mistral: return "Mistral"
        case .xAI: return "xAI Grok"
        case .nvidiaNIM: return "NVIDIA NIM"
        case .customOpenAI: return "Custom API"
        }
    }
    
    public var icon: String {
        switch self {
        case .localOllama: return "desktopcomputer"
        case .localLMStudio: return "laptopcomputer"
        case .localMLX: return "cpu"
        case .localCustom: return "network"
        case .openRouter: return "globe"
        case .claude: return "sparkles"
        case .openAI: return "brain.head.profile"
        case .gemini: return "bolt.fill"
        case .deepSeek: return "waveform.path.ecg"
        case .groq: return "bolt.horizontal.fill"
        case .mistral: return "wind"
        case .xAI: return "xmark"
        case .nvidiaNIM: return "flame.fill"
        case .customOpenAI: return "link"
        }
    }
    
    public var defaultBaseURL: String {
        switch self {
        case .localOllama: return "http://localhost:11434"
        case .localLMStudio: return "http://localhost:1234/v1"
        case .localMLX: return "http://localhost:8080/v1"
        case .localCustom: return "http://localhost:8000/v1"
        case .openRouter: return "https://openrouter.ai/api/v1"
        case .claude: return "https://api.anthropic.com/v1"
        case .openAI: return "https://api.openai.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .groq: return "https://api.groq.com/openai/v1"
        case .mistral: return "https://api.mistral.ai/v1"
        case .xAI: return "https://api.x.ai/v1"
        case .nvidiaNIM: return "https://integrate.api.nvidia.com/v1"
        case .customOpenAI: return "https://api.together.xyz/v1"
        }
    }
    
    public var defaultModel: String {
        switch self {
        case .localOllama: return "llama3.2"
        case .localLMStudio: return "local-model"
        case .localMLX: return "default"
        case .localCustom: return "default"
        case .openRouter: return "anthropic/claude-3.5-sonnet"
        case .claude: return "claude-3-5-sonnet-20241022"
        case .openAI: return "gpt-4o"
        case .gemini: return "gemini-1.5-flash"
        case .deepSeek: return "deepseek-chat"
        case .groq: return "llama-3.3-70b-versatile"
        case .mistral: return "mistral-large-latest"
        case .xAI: return "grok-2"
        case .nvidiaNIM: return "nvidia/llama-3.1-nemotron-70b-instruct"
        case .customOpenAI: return "meta-llama/Llama-3.3-70B-Instruct"
        }
    }
    
    public var suggestedModels: [String] {
        switch self {
        case .localOllama: return ["llama3.2", "mistral", "deepseek-r1", "qwen2.5", "gemma2"]
        case .localLMStudio: return ["loaded-model", "llama-3.2-3b", "mistral-7b"]
        case .localMLX: return ["mlx-community/Llama-3.2-3B-Instruct", "mlx-community/Mistral-7B-Instruct-v0.3"]
        case .localCustom: return ["default", "local-model"]
        case .openRouter: return [
            "anthropic/claude-3.5-sonnet",
            "openai/gpt-4o",
            "deepseek/deepseek-r1",
            "deepseek/deepseek-chat",
            "google/gemini-2.0-flash-exp:free",
            "meta-llama/llama-3.3-70b-instruct"
        ]
        case .claude: return [
            "claude-3-5-sonnet-20241022",
            "claude-3-5-haiku-20241022",
            "claude-3-opus-20240229"
        ]
        case .openAI: return ["gpt-4o", "gpt-4o-mini", "o1", "o3-mini"]
        case .gemini: return ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-2.0-flash"]
        case .deepSeek: return ["deepseek-chat", "deepseek-reasoner"]
        case .groq: return ["llama-3.3-70b-versatile", "llama-3.1-8b-instant", "mixtral-8x7b-32768"]
        case .mistral: return ["mistral-large-latest", "codestral-latest", "mistral-small-latest"]
        case .xAI: return ["grok-2", "grok-beta"]
        case .nvidiaNIM: return [
            "nvidia/llama-3.1-nemotron-70b-instruct",
            "nvidia/nemotron-4-340b-instruct",
            "nvidia/nemotron-mini-4b-instruct",
            "meta/llama-3.3-70b-instruct",
            "mistralai/mixtral-8x22b-instruct-v0.1"
        ]
        case .customOpenAI: return ["meta-llama/Llama-3.3-70B-Instruct", "mistralai/Mistral-7B-Instruct-v0.3"]
        }
    }
    
    public var requiresAPIKey: Bool {
        switch self {
        case .localOllama, .localLMStudio, .localMLX, .localCustom:
            return false
        default:
            return true
        }
    }
}

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    @AppStorage("cleanseProvider") public var cleanseProvider: CleanseProviderType = .localOllama
    
    // API Keys per provider
    @AppStorage("claudeApiKey") public var claudeApiKey: String = ""
    @AppStorage("claudeModel") public var claudeModel: String = "claude-3-5-sonnet-20241022"
    
    @AppStorage("openAIApiKey") public var openAIApiKey: String = ""
    @AppStorage("openAIModel") public var openAIModel: String = "gpt-4o"
    
    @AppStorage("openRouterApiKey") public var openRouterApiKey: String = ""
    @AppStorage("openRouterModel") public var openRouterModel: String = "anthropic/claude-3.5-sonnet"
    
    @AppStorage("geminiApiKey") public var geminiApiKey: String = ""
    @AppStorage("geminiModel") public var geminiModel: String = "gemini-1.5-flash"
    
    @AppStorage("deepSeekApiKey") public var deepSeekApiKey: String = ""
    @AppStorage("deepSeekModel") public var deepSeekModel: String = "deepseek-chat"
    
    @AppStorage("groqApiKey") public var groqApiKey: String = ""
    @AppStorage("groqModel") public var groqModel: String = "llama-3.3-70b-versatile"
    
    @AppStorage("mistralApiKey") public var mistralApiKey: String = ""
    @AppStorage("mistralModel") public var mistralModel: String = "mistral-large-latest"
    
    @AppStorage("xAiApiKey") public var xAiApiKey: String = ""
    @AppStorage("xAiModel") public var xAiModel: String = "grok-2"
    
    // NVIDIA NIM
    @AppStorage("nvidiaApiKey") public var nvidiaApiKey: String = ""
    @AppStorage("nvidiaBaseURL") public var nvidiaBaseURL: String = "https://integrate.api.nvidia.com/v1"
    @AppStorage("nvidiaModel") public var nvidiaModel: String = "nvidia/llama-3.1-nemotron-70b-instruct"
    
    // Custom / Generic OpenAPI
    @AppStorage("customApiUrl") public var customApiUrl: String = "https://api.together.xyz/v1"
    @AppStorage("customApiKey") public var customApiKey: String = ""
    @AppStorage("customModel") public var customModel: String = "meta-llama/Llama-3.3-70B-Instruct"
    
    // Local endpoints
    @AppStorage("ollamaHost") public var ollamaHost: String = "http://localhost:11434"
    @AppStorage("ollamaModel") public var ollamaModel: String = "llama3.2"
    
    @AppStorage("lmStudioHost") public var lmStudioHost: String = "http://localhost:1234/v1"
    @AppStorage("lmStudioModel") public var lmStudioModel: String = "loaded-model"
    
    @AppStorage("mlxHost") public var mlxHost: String = "http://localhost:8080/v1"
    @AppStorage("mlxModel") public var mlxModel: String = "default"
    
    @AppStorage("localCustomHost") public var localCustomHost: String = "http://localhost:8000/v1"
    @AppStorage("localCustomModel") public var localCustomModel: String = "default"
    
    // Policy & UI preferences
    @AppStorage("enableSoundEffects") public var enableSoundEffects: Bool = true
    @AppStorage("enableCRTOverlay") public var enableCRTOverlay: Bool = false
    @AppStorage("enableAutoLint") public var enableAutoLint: Bool = true
    @AppStorage("allowProofPenalty") public var allowProofPenalty: Bool = false
    @AppStorage("writingContext") public var writingContext: String = "Technical README / Web Landing Copy"
    
    // Author Stylometric Profile (Frontier 4: KL-Divergence Matching)
    @AppStorage("authorProfileJSON") public var authorProfileJSON: String = ""
    @AppStorage("authorSamplePath") public var authorSamplePath: String = ""
    
    /// Loads the author profile from stored JSON, if available.
    public var authorProfile: AuthorProfile? {
        get {
            guard !authorProfileJSON.isEmpty,
                  let data = authorProfileJSON.data(using: .utf8),
                  let profile = try? JSONDecoder().decode(AuthorProfile.self, from: data) else {
                return nil
            }
            return profile
        }
    }
    
    /// Saves an author profile as JSON to AppStorage.
    public func saveAuthorProfile(_ profile: AuthorProfile) {
        if let data = try? JSONEncoder().encode(profile),
           let json = String(data: data, encoding: .utf8) {
            authorProfileJSON = json
        }
    }
    
    /// Clears the stored author profile.
    public func clearAuthorProfile() {
        authorProfileJSON = ""
        authorSamplePath = ""
    }
    
    private init() {}
    
    // Helper to retrieve the active model and API Key
    public func activeCredentials() -> (baseURL: String, apiKey: String, model: String) {
        switch cleanseProvider {
        case .localOllama:
            return (ollamaHost, "", ollamaModel)
        case .localLMStudio:
            return (lmStudioHost, "", lmStudioModel)
        case .localMLX:
            return (mlxHost, "", mlxModel)
        case .localCustom:
            return (localCustomHost, "", localCustomModel)
        case .openRouter:
            return (CleanseProviderType.openRouter.defaultBaseURL, openRouterApiKey, openRouterModel)
        case .claude:
            let key = claudeApiKey.isEmpty ? (ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "") : claudeApiKey
            return (CleanseProviderType.claude.defaultBaseURL, key, claudeModel)
        case .openAI:
            let key = openAIApiKey.isEmpty ? (ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") : openAIApiKey
            return (CleanseProviderType.openAI.defaultBaseURL, key, openAIModel)
        case .gemini:
            let key = geminiApiKey.isEmpty ? (ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "") : geminiApiKey
            return (CleanseProviderType.gemini.defaultBaseURL, key, geminiModel)
        case .deepSeek:
            return (CleanseProviderType.deepSeek.defaultBaseURL, deepSeekApiKey, deepSeekModel)
        case .groq:
            return (CleanseProviderType.groq.defaultBaseURL, groqApiKey, groqModel)
        case .mistral:
            return (CleanseProviderType.mistral.defaultBaseURL, mistralApiKey, mistralModel)
        case .xAI:
            return (CleanseProviderType.xAI.defaultBaseURL, xAiApiKey, xAiModel)
        case .nvidiaNIM:
            return (nvidiaBaseURL, nvidiaApiKey, nvidiaModel)
        case .customOpenAI:
            return (customApiUrl, customApiKey, customModel)
        }
    }
}
