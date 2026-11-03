import Foundation

public struct TextNormalizer {
    
    // Invisible watermarking zero-width scalar values (mandated by AI tracking / EU AI Act Article 50)
    // We use UnicodeScalar UInt32 values because Character (extended grapheme cluster) merges ZWJ/ZWNJ into adjacent glyphs!
    public static let zeroWidthScalarValues: Set<UInt32> = [
        0x200B, // Zero-Width Space
        0x200C, // Zero-Width Non-Joiner (ZWNJ)
        0x200D, // Zero-Width Joiner (ZWJ)
        0x2060, // Word Joiner
        0xFEFF, // Zero-Width No-Break Space / BOM
        0x00AD, // Soft Hyphen
        0x200E, // Left-to-Right Mark
        0x200F  // Right-to-Left Mark
    ]
    
    /// Counts invisible tracking characters present in text
    public static func countZeroWidthUnicode(_ text: String) -> Int {
        var count = 0
        for scalar in text.unicodeScalars {
            if zeroWidthScalarValues.contains(scalar.value) {
                count += 1
            }
        }
        return count
    }
    
    /// Purges all invisible zero-width Unicode tracking characters
    public static func purgeZeroWidthUnicode(_ text: String) -> (cleaned: String, purgedCount: Int) {
        var count = 0
        var cleaned = ""
        cleaned.reserveCapacity(text.count)
        
        for scalar in text.unicodeScalars {
            if zeroWidthScalarValues.contains(scalar.value) {
                count += 1
            } else {
                cleaned.unicodeScalars.append(scalar)
            }
        }
        return (cleaned, count)
    }
    
    public static func normalise(_ t: String) -> String {
        var res = t.replacingOccurrences(of: "‑", with: "-")
        res = res.replacingOccurrences(of: "\u{00A0}", with: " ")
        res = res.replacingOccurrences(of: "’", with: "'")
        
        // Strip zero-width chars during normalisation
        res = purgeZeroWidthUnicode(res).cleaned
        
        // Collapse spaces
        let spaceRegex = try? NSRegularExpression(pattern: #"\s+"#, options: [])
        let range = NSRange(location: 0, length: res.utf16.count)
        res = spaceRegex?.stringByReplacingMatches(in: res, options: [], range: range, withTemplate: " ") ?? res
        return res.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func markdownProse(_ input: String) -> String {
        var md = input
        
        // 1. Fenced blocks ```...``` -> space
        if let r = try? NSRegularExpression(pattern: #"```[\s\S]*?```"#, options: []) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " ")
        }
        
        // 2. Images ![alt](src) -> ' . '
        if let r = try? NSRegularExpression(pattern: #"!\[[^\]]*\]\([^)]*\)"#, options: []) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " . ")
        }
        
        // 3. Links [text](url) -> 'text'
        if let r = try? NSRegularExpression(pattern: #"\[([^\]]*)\]\([^)]*\)"#, options: []) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: "$1")
        }
        
        // 4. Inline code `code` -> ' it ' (preserves clause rhythm without matching false tricolons)
        if let r = try? NSRegularExpression(pattern: #"`[^`]*`"#, options: []) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " it ")
        }
        
        // 5. Struck text ~~before~~ -> ' it '
        if let r = try? NSRegularExpression(pattern: #"~~[\s\S]*?~~"#, options: []) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " it ")
        }
        
        // 6. Headings # Title -> ' . Title . '
        if let r = try? NSRegularExpression(pattern: #"^\s{0,3}#{1,6}\s*(.*)$"#, options: [.anchorsMatchLines]) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " . $1 . ")
        }
        
        // 7. Table pipes | -> ' . '
        md = md.replacingOccurrences(of: "|", with: " . ")
        
        // 8. Bullets -> ' . '
        if let r = try? NSRegularExpression(pattern: #"^\s*(?:[-*+]|\d+\.)\s+"#, options: [.anchorsMatchLines]) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " . ")
        }
        
        // 9. Blockquotes > -> ' . '
        if let r = try? NSRegularExpression(pattern: #"^\s*>\s?"#, options: [.anchorsMatchLines]) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " . ")
        }
        
        // 10. Formatting markers * _ > -> space
        if let r = try? NSRegularExpression(pattern: #"[*_>]"#, options: []) {
            md = r.stringByReplacingMatches(in: md, options: [], range: NSRange(location: 0, length: md.utf16.count), withTemplate: " ")
        }
        
        return normalise(md)
    }
    
    public static func htmlProse(_ input: String) -> String {
        var html = input
        
        // 1. Script and Style tags with content
        if let r = try? NSRegularExpression(pattern: #"<(script|style)\b[\s\S]*?</\1>"#, options: [.caseInsensitive]) {
            html = r.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count), withTemplate: " ")
        }
        
        // 2. HTML comments
        if let r = try? NSRegularExpression(pattern: #"<!--[\s\S]*?-->"#, options: []) {
            html = r.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count), withTemplate: " ")
        }
        
        // 3. HTML tags
        if let r = try? NSRegularExpression(pattern: #"<[^>]+>"#, options: []) {
            html = r.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count), withTemplate: " ")
        }
        
        // 4. Decode HTML entities
        let decoded = decodeHTMLEntities(html)
        return normalise(decoded)
    }
    
    private static func decodeHTMLEntities(_ text: String) -> String {
        var res = text
        res = res.replacingOccurrences(of: "&amp;", with: "&")
        res = res.replacingOccurrences(of: "&lt;", with: "<")
        res = res.replacingOccurrences(of: "&gt;", with: ">")
        res = res.replacingOccurrences(of: "&quot;", with: "\"")
        res = res.replacingOccurrences(of: "&#x27;", with: "'")
        res = res.replacingOccurrences(of: "&#39;", with: "'")
        res = res.replacingOccurrences(of: "&nbsp;", with: " ")
        res = res.replacingOccurrences(of: "&mdash;", with: "—")
        res = res.replacingOccurrences(of: "&ndash;", with: "–")
        return res
    }
    
    // MARK: - LaTeX, Math & Code Placeholder Masking (Turnitout Shielding)
    
    /// Masks math environments, citations, and code blocks before linguistic transformations
    public static func maskProtectedZones(_ text: String) -> (masked: String, placeholders: [String: String]) {
        var result = text
        var placeholders: [String: String] = [:]
        var counter = 0
        
        // Helper to replace matching patterns with safe placeholders
        func maskPattern(_ pattern: String) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
            let nsStr = result as NSString
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: nsStr.length))
            
            // Iterate in reverse so ranges remain valid
            for m in matches.reversed() {
                let matchedContent = nsStr.substring(with: m.range)
                let token = "«SAFE_ZONE_\(counter)»"
                counter += 1
                placeholders[token] = matchedContent
                result = (result as NSString).replacingCharacters(in: m.range, with: token)
            }
        }
        
        // 1. Fenced Code blocks
        maskPattern(#"```[\s\S]*?```"#)
        
        // 2. Inline code
        maskPattern(#"`[^`\n]+`"#)
        
        // 3. LaTeX Display Math: $$ ... $$ and \[ ... \]
        maskPattern(#"\$\$[\s\S]*?\$\$"#)
        maskPattern(#"\\\[[\s\S]*?\\\]"#)
        
        // 4. LaTeX Math Environments: \begin{equation} ... \end{equation}, \begin{align} ...
        maskPattern(#"\\begin\{(equation|align|gather|matrix|bmatrix|vmatrix|cases)\*?\}[\s\S]*?\\end\{\1\*?\}"#)
        
        // 5. LaTeX Inline Math: $ ... $
        maskPattern(#"\$(?:\\.|[^$\\\n])+\$"#)
        
        // 6. LaTeX Citations: \cite{...}, \citep{...}, \citet{...}
        maskPattern(#"\\cite[pt]?\{[^}]+\}"#)
        
        return (result, placeholders)
    }
    
    /// Restores previously masked protected zones
    public static func restoreProtectedZones(_ text: String, placeholders: [String: String]) -> String {
        var restored = text
        for (token, original) in placeholders {
            restored = restored.replacingOccurrences(of: token, with: original)
        }
        return restored
    }
}
