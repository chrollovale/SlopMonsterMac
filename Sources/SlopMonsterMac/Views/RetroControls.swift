import SwiftUI
import AppKit

// MARK: - Pixel Monster Mascot
public enum MonsterState: Sendable {
    case clean
    case suspicious
    case alarmed
    case cleansing
}

public struct PixelMonsterView: View {
    public let state: MonsterState
    public let size: CGFloat
    public let tint: Color
    
    public init(state: MonsterState = .clean, size: CGFloat = 32, tint: Color = .green) {
        self.state = state
        self.size = size
        self.tint = tint
    }
    
    public var body: some View {
        Canvas { context, canvasSize in
            let cols = 12
            let rows = 12
            let pixelW = canvasSize.width / CGFloat(cols)
            let pixelH = canvasSize.height / CGFloat(rows)
            
            func drawPixel(x: Int, y: Int, color: Color) {
                let rect = CGRect(x: CGFloat(x) * pixelW, y: CGFloat(y) * pixelH, width: pixelW, height: pixelH)
                context.fill(Path(rect), with: .color(color))
            }
            
            // Base monster shape
            let bodyPixels: [(Int, Int)] = [
                // Horns
                (2, 1), (3, 2), (8, 2), (9, 1),
                // Head top
                (4, 2), (5, 2), (6, 2), (7, 2),
                (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3),
                // Body
                (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4),
                (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5),
                (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6),
                (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7),
                (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8),
                // Feet
                (3, 9), (4, 9), (7, 9), (8, 9),
                (2, 10), (3, 10), (8, 10), (9, 10)
            ]
            
            for (x, y) in bodyPixels {
                drawPixel(x: x, y: y, color: tint)
            }
            
            // Eyes & Expression
            let eyeColor = Color.white
            let pupilColor = Color.black
            
            switch state {
            case .clean:
                // Happy curved eyes
                drawPixel(x: 4, y: 5, color: eyeColor)
                drawPixel(x: 7, y: 5, color: eyeColor)
                drawPixel(x: 4, y: 4, color: pupilColor)
                drawPixel(x: 7, y: 4, color: pupilColor)
                // Smile
                drawPixel(x: 5, y: 7, color: pupilColor)
                drawPixel(x: 6, y: 7, color: pupilColor)
                
            case .suspicious:
                // One eyebrow raised
                drawPixel(x: 4, y: 4, color: pupilColor)
                drawPixel(x: 4, y: 5, color: eyeColor)
                drawPixel(x: 7, y: 5, color: eyeColor)
                drawPixel(x: 7, y: 5, color: pupilColor)
                // Flat mouth
                drawPixel(x: 5, y: 7, color: pupilColor)
                drawPixel(x: 6, y: 7, color: pupilColor)
                
            case .alarmed:
                // Wide open staring eyes
                drawPixel(x: 4, y: 4, color: eyeColor)
                drawPixel(x: 4, y: 5, color: eyeColor)
                drawPixel(x: 7, y: 4, color: eyeColor)
                drawPixel(x: 7, y: 5, color: eyeColor)
                drawPixel(x: 4, y: 5, color: pupilColor)
                drawPixel(x: 7, y: 5, color: pupilColor)
                // Open 'O' mouth
                drawPixel(x: 5, y: 7, color: pupilColor)
                drawPixel(x: 6, y: 7, color: pupilColor)
                drawPixel(x: 5, y: 8, color: pupilColor)
                drawPixel(x: 6, y: 8, color: pupilColor)
                
            case .cleansing:
                // Glowing star eyes
                drawPixel(x: 4, y: 5, color: Color.yellow)
                drawPixel(x: 7, y: 5, color: Color.yellow)
                drawPixel(x: 4, y: 4, color: Color.white)
                drawPixel(x: 7, y: 4, color: Color.white)
                drawPixel(x: 5, y: 7, color: Color.white)
                drawPixel(x: 6, y: 7, color: Color.white)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Retro Rubber Stamp Badge
public struct RetroStampView: View {
    public let score: Int
    
    public init(score: Int) {
        self.score = score
    }
    
    private var isClean: Bool { score == 5 }
    private var color: Color {
        if score == 5 { return Color(red: 0.15, green: 0.75, blue: 0.35) }
        if score >= 3 { return Color(red: 0.95, green: 0.6, blue: 0.1) }
        return Color(red: 0.9, green: 0.25, blue: 0.2)
    }
    
    private var title: String {
        switch score {
        case 5: return "CLEAN"
        case 4: return "FAIR"
        case 3: return "SLOPPY"
        default: return "SLOP"
        }
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isClean ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .bold))
            
            Text("\(score)/5 \(title)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(color)
        .background(color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color, lineWidth: 1.5)
        )
        .shadow(color: color.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Retro Slop Density Index Meter
public struct SlopDensityMeterView: View {
    public let sdi: Double
    
    public init(sdi: Double) {
        self.sdi = sdi
    }
    
    private var color: Color {
        if sdi == 0 { return .green }
        if sdi < 3.0 { return .yellow }
        if sdi < 8.0 { return .orange }
        return .red
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Text("SLOP DENSITY:")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            
            // LED Segment bar
            HStack(spacing: 2) {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(segmentColor(index: i))
                        .frame(width: 5, height: 10)
                        .cornerRadius(1)
                }
            }
            
            Text(String(format: "%.1f/100w", sdi))
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    private func segmentColor(index: Int) -> Color {
        let activeSegments = min(8, Int((sdi / 10.0) * 8.0))
        if index < activeSegments {
            if index < 3 { return .green }
            if index < 6 { return .yellow }
            return .red
        }
        return Color.secondary.opacity(0.2)
    }
}

// MARK: - Retro Sound Feedback
@MainActor
public struct RetroSound {
    public static func playTypeSound() {
        guard AppSettings.shared.enableSoundEffects else { return }
        NSSound(named: "Tink")?.play()
    }
    
    public static func playCleanChime() {
        guard AppSettings.shared.enableSoundEffects else { return }
        NSSound(named: "Glass")?.play()
    }
    
    public static func playTellFoundSound() {
        guard AppSettings.shared.enableSoundEffects else { return }
        NSSound(named: "Pop")?.play()
    }
}
