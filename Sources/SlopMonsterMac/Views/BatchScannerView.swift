import SwiftUI
import UniformTypeIdentifiers

public struct ScannedFileResult: Identifiable {
    public let id = UUID()
    public let path: String
    public let filename: String
    public let report: SlopReport
}

public struct BatchScannerView: View {
    @State private var scannedFiles: [ScannedFileResult] = []
    @State private var isScanning: Bool = false
    @State private var isTargeted: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Drop target & Action header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BATCH PROJECT SCANNER")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Text("Audit entire READMEs, docs repositories, or landing pages for CI-level compliance.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button("Select Folder or Files...") {
                        selectFilesViaDialog()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // Drag & Drop Area
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isTargeted ? Color.accentColor : Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .background(isTargeted ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor).opacity(0.3))
                        .cornerRadius(8)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                        Text("Drag & drop Markdown or HTML files here to audit")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                }
                .frame(height: 90)
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Results Table
            if scannedFiles.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    PixelMonsterView(state: .suspicious, size: 48, tint: .secondary)
                    Text("No files audited yet")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("AUDITED FILES (\(scannedFiles.count))") {
                        ForEach(scannedFiles) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.filename.hasSuffix(".md") ? "doc.plaintext" : "chevron.left.forwardslash.chevron.right")
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.filename)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    Text("\(item.report.wordCount) words · \(item.report.hits.count) tells")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                RetroStampView(score: item.report.classicScore)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
    
    private func selectFilesViaDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.plainText, .html, .text, .sourceCode]
        
        if panel.runModal() == .OK {
            scanURLs(panel.urls)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for p in providers {
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        self.scanURLs([url])
                    }
                }
            }
        }
    }
    
    private func scanURLs(_ urls: [URL]) {
        var results: [ScannedFileResult] = []
        let fileManager = FileManager.default
        
        for url in urls {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                        for case let fileUrl as URL in enumerator {
                            if shouldAudit(fileUrl) {
                                if let res = auditFile(at: fileUrl) {
                                    results.append(res)
                                }
                            }
                        }
                    }
                } else if shouldAudit(url) {
                    if let res = auditFile(at: url) {
                        results.append(res)
                    }
                }
            }
        }
        
        self.scannedFiles.append(contentsOf: results)
    }
    
    private func shouldAudit(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "md" || ext == "html" || ext == "htm" || ext == "txt" || ext == "tex" || ext == "swift" || ext == "py" || ext == "js" || ext == "ts"
    }
    
    private func auditFile(at url: URL) -> ScannedFileResult? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let isMd = url.pathExtension.lowercased() == "md"
        let report = SlopEngine.shared.audit(text: content, isMarkdown: isMd)
        return ScannedFileResult(path: url.path, filename: url.lastPathComponent, report: report)
    }
}
