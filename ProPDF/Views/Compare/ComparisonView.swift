import SwiftUI
import PDFKit

struct ComparisonView: View {
    let viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentResultIndex = 0
    @State private var showDifferencesOnly = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Text("Document Comparison")
                    .font(.headline)

                Spacer()

                if !results.isEmpty {
                    Button {
                        if currentResultIndex > 0 {
                            currentResultIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentResultIndex == 0)

                    Text("Page \(currentResultIndex + 1) of \(results.count)")
                        .font(.caption)
                        .monospacedDigit()

                    Button {
                        if currentResultIndex < results.count - 1 {
                            currentResultIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentResultIndex >= results.count - 1)
                }

                Toggle("Differences only", isOn: $showDifferencesOnly)
                    .font(.caption)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("No Differences Found")
                        .font(.headline)
                    Text("The documents appear to be identical.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    // Left: Original document
                    VStack(spacing: 0) {
                        Text("Original")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(4)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))

                        if let page = viewModel.pdfDocument?.page(at: currentResult.pageIndex) {
                            let thumbnail = page.thumbnail(
                                of: CGSize(width: 500, height: 700),
                                for: .mediaBox
                            )
                            ScrollView {
                                ZStack {
                                    Image(nsImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)

                                    DifferenceOverlayView(
                                        differences: currentResult.differences,
                                        pageSize: page.bounds(for: .mediaBox).size,
                                        displaySize: CGSize(width: 500, height: 700)
                                    )
                                }
                            }
                        }
                    }

                    // Right: Difference view
                    VStack(spacing: 0) {
                        Text("Differences")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(4)
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.1))

                        if let diffImage = currentResult.diffImage {
                            ScrollView {
                                Image(nsImage: diffImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        } else {
                            VStack {
                                Spacer()
                                Text("No visual diff available")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                }

                Divider()

                // Summary bar
                HStack(spacing: 16) {
                    summaryBadge(count: currentResult.addedCount, label: "Added", color: .green)
                    summaryBadge(count: currentResult.removedCount, label: "Removed", color: .red)
                    summaryBadge(count: currentResult.changedCount, label: "Changed", color: .blue)
                    Spacer()

                    Text("Total: \(currentResult.differences.count) differences")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
    }

    private var results: [ComparisonResult] {
        let all = viewModel.compare.results
        if showDifferencesOnly {
            return all.filter { $0.hasDifferences }
        }
        return all
    }

    private var currentResult: ComparisonResult {
        guard currentResultIndex < results.count else {
            return ComparisonResult(pageIndex: 0)
        }
        return results[currentResultIndex]
    }

    private func summaryBadge(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption)
        }
    }
}
