import SwiftUI

public struct DiagnosticsView: View {
    public let report: SlopReport
    public let onSelectHit: (SlopHit) -> Void
    
    @State private var selectedCategory: SlopCategory? = nil
    
    public init(report: SlopReport, onSelectHit: @escaping (SlopHit) -> Void = { _ in }) {
        self.report = report
        self.onSelectHit = onSelectHit
    }
    
    private var filteredHits: [SlopHit] {
        if let cat = selectedCategory {
            return report.hits.filter { $0.category == cat }
        }
        return report.hits
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Category Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "ALL TELLS (\(report.hits.count))",
                        isSelected: selectedCategory == nil,
                        color: .primary
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(SlopCategory.allCases) { cat in
                        let count = report.hits(for: cat).count
                        FilterChip(
                            title: "\(cat.retroBadge) (\(count))",
                            isSelected: selectedCategory == cat,
                            color: count > 0 ? cat.tintColor : .secondary
                        ) {
                            selectedCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // List of detected tells or clean banner
            if report.hits.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    PixelMonsterView(state: .clean, size: 64, tint: .green)
                    Text("NO AI TELLS DETECTED")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text("The prose scored 5/5 CLEAN across all categories.\nContinue review for accuracy and reader relevance.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Category Advice Header if filtered
                    if let cat = selectedCategory {
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    PixelMonsterView(state: .suspicious, size: 24, tint: cat.tintColor)
                                    Text(cat.mascotName)
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    Spacer()
                                    Text(cat.retroBadge)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(cat.tintColor)
                                }
                                Text(cat.editorialAdvice)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Turnitout ZipPy Entropic Perplexity Section
                    if report.wordCount >= 20 {
                        Section("ENTROPIC PERPLEXITY & CADENCE (TURNITOUT ZIPPY)") {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Human Randomness Index")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.1f%%", report.entropyResult.entropyPercentage))
                                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                                .foregroundColor(report.entropyResult.entropyPercentage >= 65 ? .green : (report.entropyResult.entropyPercentage >= 45 ? .orange : .red))
                                            Text(report.entropyResult.entropyPercentage >= 65 ? "HIGH ENTROPY" : (report.entropyResult.entropyPercentage >= 45 ? "MODERATE" : "LOW ENTROPY"))
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("ZLIB Ratio: \(String(format: "%.2f", report.entropyResult.compressionRatio))")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text("Cadence SD: \(String(format: "%.1f", report.sentenceLengthVariance)) words")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text(report.entropyResult.assessment)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Long-Document Macro Resilience Section (Central Limit Theorem Defense)
                    if report.wordCount >= 300 {
                        Section("LONG-DOCUMENT MACRO RESILIENCE (CENTRAL LIMIT THEOREM)") {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Long-Form Detection Resistance")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text("\(Int(report.macroResilienceScore))%")
                                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                                .foregroundColor(report.macroResilienceScore >= 80 ? .green : (report.macroResilienceScore >= 60 ? .orange : .red))
                                            Text(report.macroResilienceScore >= 80 ? "STRONG RESILIENCE" : "VULNERABLE OVER LENGTH")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(report.paragraphCount) Paragraphs")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text("Para SD: \(String(format: "%.1f", report.paragraphLengthVariance)) words")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text("Long documents (>1500 words) collapse statistical variance. High resilience requires paragraph-length asymmetry, varied discourse markers, and broken 5-gram chains.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Tier-3 Mathematical Frontier: Zipfian Power-Law & Syntactic Depth Section
                    if report.wordCount >= 40 {
                        Section("INFORMATION THEORY & STYLOMETRIC FRONTIER (ZIPF & YNGVE)") {
                            VStack(alignment: .leading, spacing: 8) {
                                // Row 1: Zipf's Law Metrics
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Zipf Power-Law Exponent (α)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.2f", report.zipfianMetrics.alphaSlope))
                                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                                .foregroundColor(report.zipfianMetrics.isZipfianCompliant ? .green : .orange)
                                            Text(report.zipfianMetrics.isZipfianCompliant ? "(Human Ideal: ~1.0)" : "(Deviates from ~1.0)")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Hapax Ratio: \(Int(report.zipfianMetrics.hapaxLegomenaRatio * 100))%")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(report.zipfianMetrics.hapaxLegomenaRatio >= 0.36 ? .green : .red)
                                        Text("TTR: \(String(format: "%.2f", report.zipfianMetrics.typeTokenRatio))")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Divider()
                                
                                // Row 2: Yngve Syntactic Depth
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Yngve Tree Depth SD (Syntactic Variance)")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.2f", report.syntaxMetrics.depthVariance))
                                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                                .foregroundColor(report.syntaxMetrics.isSyntacticallyDiverse ? .green : .orange)
                                            Text(report.syntaxMetrics.isSyntacticallyDiverse ? "HIGH SYNTACTIC ENTROPY" : "UNIFORM SYNTAX")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Avg Depth: \(String(format: "%.1f", report.syntaxMetrics.averageYngveDepth))")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text("Left-Branching: \(Int(report.syntaxMetrics.leftBranchingRatio * 100))%")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(report.zipfianMetrics.assessment)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Frontier 4: Author Stylometric Alignment Section (KL-Divergence Matching)
                    if report.stylometricMatch.matchPercentage < 100.0 || !report.stylometricMatch.corrections.isEmpty {
                        Section("AUTHOR STYLOMETRIC ALIGNMENT (KL-DIVERGENCE MATCHING)") {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Authentic Voice Match")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text("\(Int(report.stylometricMatch.matchPercentage))%")
                                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                                .foregroundColor(report.stylometricMatch.matchPercentage >= 80 ? .green : (report.stylometricMatch.matchPercentage >= 65 ? .orange : .red))
                                            Text(report.stylometricMatch.matchPercentage >= 80 ? "VOICE ALIGNED" : "STYLOMETRIC DRIFT")
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Total KL: \(String(format: "%.3f", report.stylometricMatch.overallKLDivergence))")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Text("Punct KL: \(String(format: "%.3f", report.stylometricMatch.punctuationKL))")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(report.stylometricMatch.assessment)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                if !report.stylometricMatch.corrections.isEmpty {
                                    Divider()
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("STYLOMETRIC CORRECTIONS TO MATCH AUTHOR:")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.orange)
                                        ForEach(report.stylometricMatch.corrections, id: \.self) { corr in
                                            Text("• \(corr)")
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Frontiers 5, 6, 7, 8: Stochastic Dynamics Dashboard
                    if report.wordCount >= 60 {
                        Section("MATHEMATICAL CEILING: STOCHASTIC DYNAMICS (HURST, FANO, BENFORD, HEAPS)") {
                            VStack(alignment: .leading, spacing: 8) {
                                // Hurst & Fano row
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Hurst Exponent (H)")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.3f", report.hurstMetrics.hurstExponent))
                                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                                .foregroundColor(report.hurstMetrics.hasLongRangeMemory ? .green : .orange)
                                            Text(report.hurstMetrics.hasLongRangeMemory ? "Persistent" : "Random Walk")
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Fano Factor (F)")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.2f", report.burstinessMetrics.fanoFactor))
                                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                                .foregroundColor(report.burstinessMetrics.isBursty ? .green : .orange)
                                            Text(report.burstinessMetrics.isBursty ? "Bursty" : "Poisson")
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Benford χ²")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.1f", report.benfordMetrics.chiSquaredStatistic))
                                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                                .foregroundColor(report.benfordMetrics.isBenfordCompliant ? .green : .orange)
                                            Text(report.benfordMetrics.isBenfordCompliant ? "Compliant" : "Anomalous")
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Heaps β")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(String(format: "%.3f", report.heapsMetrics.heapsBeta))
                                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                                .foregroundColor(report.heapsMetrics.isHeapsCompliant ? .green : .orange)
                                            Text(report.heapsMetrics.isHeapsCompliant ? "Natural" : "Saturated")
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Text("Higher-order statistical invariants: Human prose exhibits persistent memory (H>0.58), bursty word reuse (F>1.4), multi-scale Benford frequency decay (χ²<15.5), and sublinear vocabulary growth (β≈0.5).")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section("DETECTED TELLS (\(filteredHits.count))") {
                        ForEach(filteredHits) { hit in
                            HitRowView(hit: hit) {
                                onSelectHit(hit)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? color : .secondary)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? color : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct HitRowView: View {
    let hit: SlopHit
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(hit.category.retroBadge)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(hit.category.tintColor.opacity(0.15))
                    .foregroundColor(hit.category.tintColor)
                    .cornerRadius(3)
                
                Text(hit.label)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                
                Spacer()
                
                Text("Line \(hit.lineNumber)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Flagged snippet
            Text("\"\(hit.snippet)\"")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.red)
                .padding(6)
                .background(Color.red.opacity(0.08))
                .cornerRadius(4)
            
            if !hit.suggestion.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text(hit.suggestion)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
