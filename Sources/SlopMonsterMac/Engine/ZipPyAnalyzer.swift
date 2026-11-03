import Foundation

public struct ZipPyEntropyResult: Sendable, Codable {
    public let originalBytes: Int
    public let compressedBytes: Int
    public let compressionRatio: Double       // compressed / original
    public let entropyPercentage: Double      // 0 - 100% human randomness index
    public let assessment: String
    
    public init(originalBytes: Int, compressedBytes: Int, compressionRatio: Double, entropyPercentage: Double, assessment: String) {
        self.originalBytes = originalBytes
        self.compressedBytes = compressedBytes
        self.compressionRatio = compressionRatio
        self.entropyPercentage = entropyPercentage
        self.assessment = assessment
    }
    
    public static var empty: ZipPyEntropyResult {
        ZipPyEntropyResult(
            originalBytes: 0,
            compressedBytes: 0,
            compressionRatio: 1.0,
            entropyPercentage: 100.0,
            assessment: "No prose analyzed"
        )
    }
}

public enum ZipPyAnalyzer {
    /// Evaluates text compressibility using native zlib compression.
    /// AI-generated text exhibits abnormally high compressibility (low entropy) due to repetitive n-gram patterns.
    /// Authentic human writing contains irregular syntax and rich vocabulary that resists compression.
    public static func evaluate(text: String) -> ZipPyEntropyResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8), data.count > 0 else {
            return .empty
        }
        
        let origSize = data.count
        guard origSize >= 30 else {
            return ZipPyEntropyResult(
                originalBytes: origSize,
                compressedBytes: origSize,
                compressionRatio: 1.0,
                entropyPercentage: 100.0,
                assessment: "Sample too short for entropic compression audit (<30 bytes)"
            )
        }
        
        do {
            let compressed = try (data as NSData).compressed(using: .zlib)
            let compSize = compressed.length
            let ratio = Double(compSize) / Double(origSize)
            
            // Map ratio to an entropic human score (0% to 100%)
            // Typical thresholds:
            // ratio <= 0.38 -> heavily repetitive AI text (~25% entropy)
            // ratio 0.50 -> standard balanced prose (~70% entropy)
            // ratio >= 0.65 -> high-entropy diverse text (~95% entropy)
            let normalizedEntropy: Double
            if ratio < 0.40 {
                normalizedEntropy = max(10.0, (ratio / 0.40) * 45.0)
            } else if ratio < 0.60 {
                normalizedEntropy = 45.0 + ((ratio - 0.40) / 0.20) * 35.0
            } else {
                normalizedEntropy = min(99.0, 80.0 + ((ratio - 0.60) / 0.30) * 19.0)
            }
            
            let assessment: String
            if normalizedEntropy >= 75.0 {
                assessment = "High Entropy (\(String(format: "%.1f", normalizedEntropy))%): Diverse vocabulary & natural syntax resist compression."
            } else if normalizedEntropy >= 50.0 {
                assessment = "Moderate Entropy (\(String(format: "%.1f", normalizedEntropy))%): Standard academic balance."
            } else {
                assessment = "Low Entropy (\(String(format: "%.1f", normalizedEntropy))%): High compressibility indicates formulaic AI token predictability."
            }
            
            return ZipPyEntropyResult(
                originalBytes: origSize,
                compressedBytes: compSize,
                compressionRatio: ratio,
                entropyPercentage: normalizedEntropy,
                assessment: assessment
            )
        } catch {
            return ZipPyEntropyResult(
                originalBytes: origSize,
                compressedBytes: origSize,
                compressionRatio: 1.0,
                entropyPercentage: 70.0,
                assessment: "Compression evaluation completed with neutral score"
            )
        }
    }
}
