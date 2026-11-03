import SwiftUI

public struct DiffView: View {
    public let original: String
    public let revised: String
    
    @State private var diffTokens: [DiffToken] = []
    
    public init(original: String, revised: String) {
        self.original = original
        self.revised = revised
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REVISION DIFF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("Deleted Slop")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Clean Replacement")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    WrappingHStack(tokens: diffTokens)
                        .padding(16)
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onAppear {
            diffTokens = DiffEngine.computeWordDiff(original: original, revised: revised)
        }
        .onChange(of: revised) { _, newRev in
            diffTokens = DiffEngine.computeWordDiff(original: original, revised: newRev)
        }
    }
}

// Helper view to wrap tokens
struct WrappingHStack: View {
    let tokens: [DiffToken]
    
    var body: some View {
        // Render rich attributed text for clean wrapping
        Text(buildAttributedString())
            .font(.system(size: 13, design: .monospaced))
            .lineSpacing(6)
            .textSelection(.enabled)
    }
    
    private func buildAttributedString() -> AttributedString {
        var result = AttributedString("")
        
        for token in tokens {
            var str = AttributedString(token.text)
            switch token.kind {
            case .unchanged:
                str.foregroundColor = .primary
            case .deleted:
                str.foregroundColor = .red
                str.strikethroughStyle = .single
                str.backgroundColor = Color.red.opacity(0.12)
            case .inserted:
                str.foregroundColor = Color(red: 0.1, green: 0.7, blue: 0.3)
                str.backgroundColor = Color.green.opacity(0.15)
                str.inlinePresentationIntent = .stronglyEmphasized
            }
            result.append(str)
        }
        
        return result
    }
}
