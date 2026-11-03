import Foundation

public struct CleanseResponse: Sendable {
    public let cleansedText: String
    public let changeNotes: [String]
    public let providerName: String
    public let durationSeconds: Double
    
    public init(cleansedText: String, changeNotes: [String], providerName: String, durationSeconds: Double) {
        self.cleansedText = cleansedText
        self.changeNotes = changeNotes
        self.providerName = providerName
        self.durationSeconds = durationSeconds
    }
}

public actor CleanseService {
    public static let shared = CleanseService()
    
    private let systemPrompt = """
    You are the SlopMonster DIPPER & Structural Evasion Cleanse Engine (NeurIPS 2023 / ICML 2024).
    Your mission: Completely eradicate AI statistical fingerprints, transformer softmax predictability, and expository monotony from the supplied text while preserving 100% of the technical facts, equations, and code blocks.
    
    PRINCIPLE 1: DISCOURSE & TOPOLOGY INVERSION (DIPPER Formulation)
    - Do NOT summarize like an encyclopedia or textbook.
    - Invert the sequence of propositions within paragraphs: lead with the empirical finding, constraint, or trade-off FIRST, and the abstract principle second.
    - Remove throat-clearing openings ("In today's fast-paced digital era", "It is important to delve deep into", "At its core"). Start immediately with the action or technical thesis.
    
    PRINCIPLE 2: SYNTACTIC DECOUPLING (Destroying the 20-Word Metronome)
    - AI text suffers from uniform sentence lengths (18-24 words per sentence). Humans vary wildly.
    - Enforce asymmetric rhythm: mix punchy 3-6 word staccato assertions ("The bottleneck was latency.", "That failed in production.", "The trade-off is stark.") with longer, complex clauses.
    - Break up formulaic compound-complex sentences.
    
    PRINCIPLE 3: PRAGMATIC REALISM & CONVERSATIONAL ANCHORS (Binoculars Evasion)
    - Replace puffed-up marketing fluff ("delve", "seamlessly", "elevate", "leverage", "robust framework", "comprehensive tapestry", "game-changing", "stands as a testament") with grounded engineering realism.
    - Inject genuine pragmatic qualifiers: "in practice", "at first glance, this seems ideal; yet", "production benchmarks show", "to be fair".
    - Cut all negated contrasts ("not just X, it's Y"), rule-of-three flourishes ("faster, smarter, and better"), and fabricated social proof metrics ("10,000+ happy users").
    
    PRINCIPLE 4: LATEX & CODE PRESERVATION
    - Never alter, reformat, or corrupt LaTeX math ($...$, $$...$$) or code blocks. Keep all equations 100% character-for-character intact.
    
    OUTPUT REQUIREMENTS:
    Respond strictly with valid JSON with this exact schema:
    {
      "cleansed_copy": "<the complete revised prose/document>",
      "change_notes": [
        "<substantive structural change 1>",
        "<substantive structural change 2>",
        "<substantive structural change 3>"
      ]
    }
    No markdown formatting around the JSON (no ```json code fences).
    """
    
    private init() {}
    
    // Fetch available local Ollama models
    public func fetchOllamaModels(host: String = "http://localhost:11434") async -> [String] {
        guard let url = URL(string: "\(host)/api/tags") else { return [] }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            
            struct TagModel: Decodable { let name: String }
            struct TagsResponse: Decodable { let models: [TagModel] }
            
            let res = try JSONDecoder().decode(TagsResponse.self, from: data)
            return res.models.map { $0.name }
        } catch {
            return []
        }
    }
    
    // Universal Connection Tester
    public func testConnection(
        provider: CleanseProviderType,
        baseURL: String,
        apiKey: String,
        model: String
    ) async -> (online: Bool, message: String) {
        switch provider {
        case .localOllama:
            guard let url = URL(string: "\(baseURL)/api/tags") else { return (false, "Invalid URL") }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 3
                let (_, res) = try await URLSession.shared.data(for: req)
                if (res as? HTTPURLResponse)?.statusCode == 200 {
                    let models = await fetchOllamaModels(host: baseURL)
                    return (true, "Ollama online! (\(models.count) models discovered: \(models.prefix(3).joined(separator: ", ")))")
                }
                return (false, "Ollama returned status \((res as? HTTPURLResponse)?.statusCode ?? 0)")
            } catch {
                return (false, "Cannot reach Ollama at \(baseURL). Run 'ollama serve' in Terminal.")
            }
            
        case .localMLX, .localLMStudio, .localCustom:
            let testURLString = baseURL.hasSuffix("/v1") ? "\(baseURL)/models" : "\(baseURL)/v1/models"
            guard let url = URL(string: testURLString) else { return (false, "Invalid URL") }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 3
                let (_, res) = try await URLSession.shared.data(for: req)
                if (res as? HTTPURLResponse)?.statusCode == 200 {
                    return (true, "\(provider.shortName) endpoint is reachable!")
                }
                return (false, "\(provider.shortName) returned status \((res as? HTTPURLResponse)?.statusCode ?? 0)")
            } catch {
                return (false, "Cannot reach \(provider.shortName) on \(baseURL). Verify the local server is running.")
            }
            
        case .claude:
            guard !apiKey.isEmpty else { return (false, "Anthropic API Key is missing.") }
            guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return (false, "Invalid URL") }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 6
            let testBody: [String: Any] = [
                "model": model.isEmpty ? "claude-3-5-haiku-20241022" : model,
                "max_tokens": 10,
                "messages": [["role": "user", "content": "ping"]]
            ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: testBody)
            do {
                let (_, res) = try await URLSession.shared.data(for: req)
                let code = (res as? HTTPURLResponse)?.statusCode ?? 0
                if code == 200 { return (true, "Claude API connection successful!") }
                return (false, "Claude returned HTTP \(code). Check API Key.")
            } catch {
                return (false, "Connection error: \(error.localizedDescription)")
            }
            
        case .gemini:
            guard !apiKey.isEmpty else { return (false, "Google Gemini API Key is missing.") }
            let testURLString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
            guard let url = URL(string: testURLString) else { return (false, "Invalid URL") }
            do {
                var req = URLRequest(url: url)
                req.timeoutInterval = 6
                let (_, res) = try await URLSession.shared.data(for: req)
                if (res as? HTTPURLResponse)?.statusCode == 200 { return (true, "Gemini API connection successful!") }
                return (false, "Gemini returned HTTP \((res as? HTTPURLResponse)?.statusCode ?? 0). Check API Key.")
            } catch {
                return (false, "Gemini connection error: \(error.localizedDescription)")
            }
            
        case .openAI, .openRouter, .deepSeek, .groq, .mistral, .xAI, .nvidiaNIM, .customOpenAI:
            guard !apiKey.isEmpty || !provider.requiresAPIKey else { return (false, "API Key is required for \(provider.shortName).") }
            let modelsURL = baseURL.hasSuffix("/v1") ? "\(baseURL)/models" : "\(baseURL)/v1/models"
            guard let url = URL(string: modelsURL) else { return (false, "Invalid Base URL: \(baseURL)") }
            do {
                var req = URLRequest(url: url)
                if !apiKey.isEmpty {
                    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                }
                req.timeoutInterval = 6
                let (_, res) = try await URLSession.shared.data(for: req)
                let code = (res as? HTTPURLResponse)?.statusCode ?? 0
                if code == 200 {
                    return (true, "\(provider.shortName) connection verified!")
                }
                return (false, "\(provider.shortName) returned HTTP \(code). Check Base URL and Key.")
            } catch {
                return (false, "Failed to connect to \(baseURL): \(error.localizedDescription)")
            }
        }
    }
    
    // Main Cleanse Router
    public func cleanse(
        draft: String,
        provider: CleanseProviderType,
        baseURL: String,
        apiKey: String,
        model: String,
        context: String = ""
    ) async throws -> CleanseResponse {
        let startTime = Date()
        let userPrompt = context.isEmpty ? draft : "Document Context/Audience: \(context)\n\nDraft:\n\(draft)"
        
        switch provider {
        case .localOllama:
            return try await executeOllama(
                draft: userPrompt,
                host: baseURL,
                model: model,
                startTime: startTime
            )
            
        case .claude:
            return try await executeClaude(
                draft: userPrompt,
                apiKey: apiKey,
                model: model,
                startTime: startTime
            )
            
        case .gemini:
            return try await executeGemini(
                draft: userPrompt,
                apiKey: apiKey,
                model: model,
                startTime: startTime
            )
            
        case .openAI, .openRouter, .deepSeek, .groq, .mistral, .xAI, .nvidiaNIM, .localLMStudio, .localMLX, .localCustom, .customOpenAI:
            return try await executeOpenAICompatible(
                draft: userPrompt,
                provider: provider,
                baseURL: baseURL,
                apiKey: apiKey,
                model: model,
                startTime: startTime
            )
        }
    }
    
    // 1. Ollama Execution
    private func executeOllama(draft: String, host: String, model: String, startTime: Date) async throws -> CleanseResponse {
        guard let url = URL(string: "\(host)/api/generate") else { throw CleanseError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        
        let payload: [String: Any] = [
            "model": model.isEmpty ? "llama3.2" : model,
            "system": systemPrompt,
            "prompt": draft,
            "format": "json",
            "stream": false,
            "options": ["temperature": 0.2]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CleanseError.networkError("Failed to connect to Ollama. Run 'ollama serve' in Terminal.")
        }
        
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw CleanseError.networkError("Ollama returned HTTP \(code). Verify model '\(model)' is pulled.")
        }
        
        struct OllamaPayload: Decodable { let response: String }
        let ollamaRes = try JSONDecoder().decode(OllamaPayload.self, from: data)
        let duration = Date().timeIntervalSince(startTime)
        return try parseCleanseJSON(rawOutput: ollamaRes.response, provider: "Ollama (\(model))", duration: duration)
    }
    
    // 2. Claude Execution
    private func executeClaude(draft: String, apiKey: String, model: String, startTime: Date) async throws -> CleanseResponse {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { throw CleanseError.missingAPIKey }
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { throw CleanseError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(cleanKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        
        let payload: [String: Any] = [
            "model": model.isEmpty ? "claude-3-5-sonnet-20241022" : model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [["role": "user", "content": draft]],
            "temperature": 0.2
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse else { throw CleanseError.networkError("Invalid HTTP response") }
        
        if httpRes.statusCode != 200 {
            if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = errJson["error"] as? [String: Any],
               let message = errObj["message"] as? String {
                throw CleanseError.apiError("Claude Error (\(httpRes.statusCode)): \(message)")
            }
            throw CleanseError.apiError("Claude returned HTTP error \(httpRes.statusCode)")
        }
        
        struct ClaudeMessageResponse: Decodable {
            struct ContentBlock: Decodable { let text: String? }
            let content: [ContentBlock]
        }
        let claudeRes = try JSONDecoder().decode(ClaudeMessageResponse.self, from: data)
        let outputText = claudeRes.content.compactMap { $0.text }.joined(separator: "\n")
        let duration = Date().timeIntervalSince(startTime)
        return try parseCleanseJSON(rawOutput: outputText, provider: "Claude (\(model))", duration: duration)
    }
    
    // 3. Google Gemini Execution
    private func executeGemini(draft: String, apiKey: String, model: String, startTime: Date) async throws -> CleanseResponse {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { throw CleanseError.missingAPIKey }
        
        let targetModel = model.isEmpty ? "gemini-1.5-flash" : model
        let urlStr = "https://generativelanguage.googleapis.com/v1beta/models/\(targetModel):generateContent?key=\(cleanKey)"
        guard let url = URL(string: urlStr) else { throw CleanseError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        
        let body: [String: Any] = [
            "contents": [["parts": [["text": "\(systemPrompt)\n\nDraft:\n\(draft)"]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.2
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw CleanseError.apiError("Gemini returned HTTP \(code)")
        }
        
        struct GeminiRes: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable { let text: String }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }
        let res = try JSONDecoder().decode(GeminiRes.self, from: data)
        let text = res.candidates.first?.content.parts.first?.text ?? ""
        let duration = Date().timeIntervalSince(startTime)
        return try parseCleanseJSON(rawOutput: text, provider: "Gemini (\(targetModel))", duration: duration)
    }
    
    // 4. Universal OpenAI-Compatible Execution (OpenAI, OpenRouter, DeepSeek, Groq, Mistral, xAI, LM Studio, Apple MLX)
    private func executeOpenAICompatible(
        draft: String,
        provider: CleanseProviderType,
        baseURL: String,
        apiKey: String,
        model: String,
        startTime: Date
    ) async throws -> CleanseResponse {
        var cleanBase = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanBase.hasSuffix("/") { cleanBase.removeLast() }
        
        let endpoint = cleanBase.hasSuffix("/chat/completions") ? cleanBase :
            (cleanBase.hasSuffix("/v1") ? "\(cleanBase)/chat/completions" : "\(cleanBase)/v1/chat/completions")
        
        guard let url = URL(string: endpoint) else { throw CleanseError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // OpenRouter custom identification headers
        if provider == .openRouter {
            request.setValue("https://github.com/ItsssssJack/SlopMonster", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("SlopMonsterMac", forHTTPHeaderField: "X-Title")
        }
        
        let targetModel = model.isEmpty ? provider.defaultModel : model
        var payload: [String: Any] = [
            "model": targetModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": draft]
            ],
            "temperature": 0.2
        ]
        
        // Only include response_format for providers that universally support json_object mode
        // Models like Nemotron on NVIDIA NIM or DeepSeek R1 often reject 'response_format' with HTTP 400
        if provider == .openAI || provider == .groq {
            payload["response_format"] = ["type": "json_object"]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CleanseError.networkError("Failed to reach \(provider.shortName) at \(endpoint): \(error.localizedDescription)")
        }
        
        guard let httpRes = response as? HTTPURLResponse else { throw CleanseError.networkError("Invalid HTTP response") }
        
        if httpRes.statusCode != 200 {
            if let errJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = errJson["error"] as? [String: Any],
               let message = errObj["message"] as? String {
                throw CleanseError.apiError("\(provider.shortName) Error (\(httpRes.statusCode)): \(message)")
            }
            throw CleanseError.apiError("\(provider.shortName) returned HTTP \(httpRes.statusCode)")
        }
        
        struct Choice: Decodable {
            struct Msg: Decodable { let content: String }
            let message: Msg
        }
        struct ResponseBody: Decodable { let choices: [Choice] }
        
        let res = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let rawText = res.choices.first?.message.content else {
            throw CleanseError.parsingError("Model response contained no message content.")
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return try parseCleanseJSON(rawOutput: rawText, provider: "\(provider.shortName) (\(targetModel))", duration: duration)
    }
    
    // Robust JSON response parsing with fenced-code extraction and sentinel fallback
    private func parseCleanseJSON(rawOutput: String, provider: String, duration: Double) throws -> CleanseResponse {
        var clean = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        struct StructuredCleanse: Decodable {
            let cleansed_copy: String
            let change_notes: [String]?
        }
        
        // 1. Try extracting from fenced markdown block anywhere in the output
        if let fencedRegex = try? NSRegularExpression(pattern: #"```(?:json)?\s*(\{[\s\S]*?\})\s*```"#, options: [.caseInsensitive]),
           let match = fencedRegex.firstMatch(in: clean, options: [], range: NSRange(location: 0, length: (clean as NSString).length)) {
            let jsonSubstring = (clean as NSString).substring(with: match.range(at: 1))
            if let data = jsonSubstring.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(StructuredCleanse.self, from: data) {
                let sanitized = TextNormalizer.purgeZeroWidthUnicode(decoded.cleansed_copy).cleaned
                return CleanseResponse(
                    cleansedText: sanitized,
                    changeNotes: decoded.change_notes ?? [],
                    providerName: provider,
                    durationSeconds: duration
                )
            }
        }
        
        // 2. Strip leading/trailing backticks if present
        if clean.hasPrefix("```") {
            let lines = clean.components(separatedBy: .newlines)
            let filtered = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            clean = filtered.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 3. Try direct decode
        if let data = clean.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(StructuredCleanse.self, from: data) {
            let sanitized = TextNormalizer.purgeZeroWidthUnicode(decoded.cleansed_copy).cleaned
            return CleanseResponse(
                cleansedText: sanitized,
                changeNotes: decoded.change_notes ?? [],
                providerName: provider,
                durationSeconds: duration
            )
        }
        
        // 4. Try finding outermost { ... } in case the model prefixed conversational chit-chat
        if let firstBrace = clean.firstIndex(of: "{"),
           let lastBrace = clean.lastIndex(of: "}"),
           firstBrace < lastBrace {
            let potentialJson = String(clean[firstBrace...lastBrace])
            if let data = potentialJson.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(StructuredCleanse.self, from: data) {
                let sanitized = TextNormalizer.purgeZeroWidthUnicode(decoded.cleansed_copy).cleaned
                return CleanseResponse(
                    cleansedText: sanitized,
                    changeNotes: decoded.change_notes ?? [],
                    providerName: provider,
                    durationSeconds: duration
                )
            }
        }
        
        // 5. Classical SlopMonster Sentinel Fallback: <<<SLOPMONSTER-NOTES>>>
        let sentinel = "<<<SLOPMONSTER-NOTES>>>"
        if clean.contains(sentinel) {
            let parts = clean.components(separatedBy: sentinel)
            let body = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let notesText = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let notes = notesText.components(separatedBy: .newlines)
                .map { $0.replacingOccurrences(of: #"^[-*•]\s*"#, with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            let sanitized = TextNormalizer.purgeZeroWidthUnicode(body).cleaned
            return CleanseResponse(
                cleansedText: sanitized,
                changeNotes: notes,
                providerName: provider,
                durationSeconds: duration
            )
        }
        
        let sanitized = TextNormalizer.purgeZeroWidthUnicode(clean).cleaned
        return CleanseResponse(
            cleansedText: sanitized,
            changeNotes: ["Cleanse completed without structured notes marker."],
            providerName: provider,
            durationSeconds: duration
        )
    }
}

public enum CleanseError: LocalizedError {
    case invalidURL
    case missingAPIKey
    case networkError(String)
    case apiError(String)
    case parsingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "The configured model endpoint URL is invalid."
        case .missingAPIKey: return "API Key is required for this provider. Configure it in Preferences (⌘,)."
        case .networkError(let msg): return msg
        case .apiError(let msg): return msg
        case .parsingError(let msg): return msg
        }
    }
}
