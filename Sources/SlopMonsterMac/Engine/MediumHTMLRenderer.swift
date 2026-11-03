import Foundation

/// MediumHTMLRenderer converts optimized Markdown documents into semantic HTML
/// tailored specifically for Medium's ProseMirror/MediumEditor paste processor.
/// When pasted into Medium (Chrome, Safari, Arc, Firefox), Medium reads the 'text/html'
/// clipboard flavor and automatically renders native Story Titles (h1), Subtitles (h2),
/// Section Headers (h3), 3-dot dividers (hr), bold (strong), italics (em), and blockquotes.
public enum MediumHTMLRenderer {
    
    /// Converts a Markdown document into rich HTML for clipboard transfer
    public static func renderHTML(fromMarkdown markdown: String) -> String {
        // Step 0: Shield code and LaTeX math
        let (masked, placeholders) = TextNormalizer.maskProtectedZones(markdown)
        
        let lines = masked.components(separatedBy: "\n")
        var htmlBlocks: [String] = []
        
        var inList = false
        var listItems: [String] = []
        var inQuote = false
        var quoteLines: [String] = []
        var foundTitle = false
        var expectingSubtitle = false
        
        func flushList() {
            if inList {
                htmlBlocks.append("<ul>\n" + listItems.map { "  <li>\($0)</li>" }.joined(separator: "\n") + "\n</ul>")
                listItems.removeAll()
                inList = false
            }
        }
        
        func flushQuote() {
            if inQuote {
                let quoteContent = quoteLines.joined(separator: " ")
                htmlBlocks.append("<blockquote><p>\(formatInline(quoteContent))</p></blockquote>")
                quoteLines.removeAll()
                inQuote = false
            }
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Empty line
            if trimmed.isEmpty {
                flushList()
                flushQuote()
                continue
            }
            
            // Divider: --- or ***
            if trimmed == "---" || trimmed == "***" || trimmed == "–--" {
                flushList()
                flushQuote()
                htmlBlocks.append("<hr/>")
                expectingSubtitle = false
                continue
            }
            
            // Kicker: e.g. "SYSTEMS & ENGINEERING // ARCHITECTURE DEEP DIVE"
            if !foundTitle && trimmed == trimmed.uppercased() && (trimmed.contains("//") || trimmed.contains("—") || trimmed.count < 60) && !trimmed.hasPrefix("#") && !trimmed.hasPrefix("![") {
                flushList()
                flushQuote()
                htmlBlocks.append("<p><small><strong>\(trimmed)</strong></small></p>")
                continue
            }
            
            // H1 Title: # Title
            if trimmed.hasPrefix("# ") && !foundTitle {
                flushList()
                flushQuote()
                let titleText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                htmlBlocks.append("<h1>\(formatInline(titleText))</h1>")
                foundTitle = true
                expectingSubtitle = true
                continue
            }
            
            // Subtitle immediately following H1
            if expectingSubtitle {
                flushList()
                flushQuote()
                var subText = trimmed
                if subText.hasPrefix("*") && subText.hasSuffix("*") && subText.count > 2 {
                    subText = String(subText.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                }
                // Check if it's the read-time telemetry badge
                if subText.contains("min read") && subText.contains("words") {
                    // Do not render internal telemetry badge in HTML body for Medium; Medium computes this natively!
                    expectingSubtitle = false
                    continue
                }
                htmlBlocks.append("<h2>\(formatInline(subText))</h2>")
                expectingSubtitle = false
                continue
            }
            
            // H2 Header: ## Header -> maps to Medium's large header (h3 in standard semantic HTML)
            if trimmed.hasPrefix("## ") {
                flushList()
                flushQuote()
                let hText = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                htmlBlocks.append("<h3>\(formatInline(hText))</h3>")
                continue
            }
            
            // H3 Header: ### Header -> maps to Medium's sub-header (h4 in standard semantic HTML)
            if trimmed.hasPrefix("### ") {
                flushList()
                flushQuote()
                let hText = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                htmlBlocks.append("<h4>\(formatInline(hText))</h4>")
                continue
            }
            
            // Blockquote: > Quote
            if trimmed.hasPrefix(">") {
                flushList()
                inQuote = true
                let qText = trimmed.replacingOccurrences(of: #"^>\s*"#, with: "", options: .regularExpression)
                quoteLines.append(qText)
                continue
            }
            
            // Bullet list item: - Item or * Item
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushQuote()
                inList = true
                let itemText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                listItems.append(formatInline(itemText))
                continue
            }
            
            // Image: ![alt](url)
            if trimmed.hasPrefix("![") && trimmed.contains("](") {
                flushList()
                flushQuote()
                if let (alt, url) = extractImageParts(trimmed) {
                    htmlBlocks.append("<figure><img src=\"\(url)\" alt=\"\(alt)\"/></figure>")
                }
                continue
            }
            
            // Image caption: *Figure 1: ...*
            if trimmed.hasPrefix("*Figure") && trimmed.hasSuffix("*") {
                // If the previous block was a figure, attach the figcaption
                if let last = htmlBlocks.last, last.hasPrefix("<figure><img") {
                    htmlBlocks.removeLast()
                    let caption = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                    if let (alt, url) = extractImagePartsFromFigure(last) {
                        htmlBlocks.append("<figure><img src=\"\(url)\" alt=\"\(alt)\"/><figcaption>\(formatInline(caption))</figcaption></figure>")
                        continue
                    }
                }
            }
            
            // Isolated short heading candidate (e.g. "Confirmation Bias" without #)
            if trimmed.count < 45 && !trimmed.hasSuffix(".") && !trimmed.hasSuffix(",") && !trimmed.hasSuffix(";") && !trimmed.contains(" ") && trimmed.first?.isUppercase == true {
                flushList()
                flushQuote()
                htmlBlocks.append("<h3>\(formatInline(trimmed))</h3>")
                continue
            }
            
            // Standard body paragraph
            flushList()
            flushQuote()
            htmlBlocks.append("<p>\(formatInline(trimmed))</p>")
        }
        
        flushList()
        flushQuote()
        
        var fullHTML = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Medium Story</title>
        </head>
        <body>
        \(htmlBlocks.joined(separator: "\n\n"))
        </body>
        </html>
        """
        
        // Step Final: Restore protected zones
        for (token, original) in placeholders {
            // If it's code, format as HTML code block
            if original.hasPrefix("```") {
                let cleanCode = original.replacingOccurrences(of: #"```[a-zA-Z0-9]*\n?"#, with: "", options: .regularExpression).replacingOccurrences(of: "\n```", with: "")
                let escaped = escapeHTML(cleanCode)
                fullHTML = fullHTML.replacingOccurrences(of: token, with: "<pre><code>\(escaped)</code></pre>")
            } else if original.hasPrefix("`") && original.hasSuffix("`") {
                let cleanInline = String(original.dropFirst().dropLast())
                fullHTML = fullHTML.replacingOccurrences(of: token, with: "<code>\(escapeHTML(cleanInline))</code>")
            } else {
                // LaTeX math: wrap in clean math styling for web browser
                fullHTML = fullHTML.replacingOccurrences(of: token, with: "<code>\(escapeHTML(original))</code>")
            }
        }
        
        return fullHTML
    }
    
    // MARK: - Inline Formatting
    
    private static func formatInline(_ text: String) -> String {
        var res = escapeHTML(text)
        
        // Bold: **text** -> <strong>text</strong>
        if let bRegex = try? NSRegularExpression(pattern: #"\*\*([^*]+)\*\*"#, options: []) {
            let ns = res as NSString
            res = bRegex.stringByReplacingMatches(in: res, options: [], range: NSRange(location: 0, length: ns.length), withTemplate: "<strong>$1</strong>")
        }
        
        // Italics: *text* -> <em>text</em>
        if let iRegex = try? NSRegularExpression(pattern: #"(?<!\*)\*([^*]+)\*(?!\*)"#, options: []) {
            let ns = res as NSString
            res = iRegex.stringByReplacingMatches(in: res, options: [], range: NSRange(location: 0, length: ns.length), withTemplate: "<em>$1</em>")
        }
        
        // Em-dash: -- -> —
        res = res.replacingOccurrences(of: " -- ", with: " — ")
        
        return res
    }
    
    private static func escapeHTML(_ text: String) -> String {
        var res = text
        res = res.replacingOccurrences(of: "&", with: "&amp;")
        res = res.replacingOccurrences(of: "<", with: "&lt;")
        res = res.replacingOccurrences(of: ">", with: "&gt;")
        return res
    }
    
    private static func extractImageParts(_ text: String) -> (alt: String, url: String)? {
        guard let altStart = text.range(of: "!["),
              let altEnd = text.range(of: "]("),
              let urlEnd = text.range(of: ")", options: .backwards) else {
            return nil
        }
        let alt = String(text[altStart.upperBound..<altEnd.lowerBound])
        let url = String(text[altEnd.upperBound..<urlEnd.lowerBound])
        return (alt, url)
    }
    
    private static func extractImagePartsFromFigure(_ figureTag: String) -> (alt: String, url: String)? {
        guard let srcStart = figureTag.range(of: "src=\""),
              let srcEnd = figureTag[srcStart.upperBound...].range(of: "\""),
              let altStart = figureTag.range(of: "alt=\""),
              let altEnd = figureTag[altStart.upperBound...].range(of: "\"") else {
            return nil
        }
        let url = String(figureTag[srcStart.upperBound..<srcEnd.lowerBound])
        let alt = String(figureTag[altStart.upperBound..<altEnd.lowerBound])
        return (alt, url)
    }
}
