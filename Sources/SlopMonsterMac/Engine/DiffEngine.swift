import Foundation

public enum DiffTokenKind: Equatable, Sendable {
    case unchanged
    case deleted
    case inserted
}

public struct DiffToken: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let text: String
    public let kind: DiffTokenKind
    
    public init(text: String, kind: DiffTokenKind) {
        self.text = text
        self.kind = kind
    }
}

public struct DiffEngine {
    // Computes a word-by-word diff between draft and cleansed text
    public static func computeWordDiff(original: String, revised: String) -> [DiffToken] {
        let origWords = tokenize(original)
        let revWords = tokenize(revised)
        
        // Longest Common Subsequence (LCS) dynamic programming table
        let n = origWords.count
        let m = revWords.count
        
        // Safety bound for performance on huge documents
        if n > 2000 || m > 2000 {
            // Simplified fallback if document is extremely large
            return [
                DiffToken(text: original, kind: .deleted),
                DiffToken(text: revised, kind: .inserted)
            ]
        }
        
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        for i in 1...max(1, n) {
            if i > n { break }
            for j in 1...max(1, m) {
                if j > m { break }
                if origWords[i - 1].lowercased() == revWords[j - 1].lowercased() {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }
        
        var tokens: [DiffToken] = []
        var i = n
        var j = m
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && origWords[i - 1].lowercased() == revWords[j - 1].lowercased() {
                tokens.append(DiffToken(text: revWords[j - 1], kind: .unchanged))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
                tokens.append(DiffToken(text: revWords[j - 1], kind: .inserted))
                j -= 1
            } else if i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j]) {
                tokens.append(DiffToken(text: origWords[i - 1], kind: .deleted))
                i -= 1
            }
        }
        
        return tokens.reversed()
    }
    
    private static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        let pattern = #"\S+|\s+"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            for m in matches {
                tokens.append(nsText.substring(with: m.range))
            }
        } else {
            tokens = text.components(separatedBy: .whitespacesAndNewlines)
        }
        return tokens
    }
}
