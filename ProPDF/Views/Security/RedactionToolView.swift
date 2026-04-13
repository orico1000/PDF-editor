import SwiftUI
import PDFKit

struct RedactionToolView: View {
    let viewModel: DocumentViewModel

    @State private var regions: [RedactionRegion] = []
    @State private var isDrawing = false
    @State private var drawStart = CGPoint.zero
    @State private var drawEnd = CGPoint.zero

    var body: some View {
        ZStack {
            // Drawing layer for marking redactions
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            if !isDrawing {
                                isDrawing = true
                                drawStart = value.startLocation
                            }
                            drawEnd = value.location
                        }
                        .onEnded { value in
                            addRedactionRegion(from: drawStart, to: value.location)
                            isDrawing = false
                        }
                )
                .allowsHitTesting(viewModel.state.editorMode == .redact)

            // Drawing preview
            if isDrawing {
                let rect = normalizedRect(from: drawStart, to: drawEnd)
                Rectangle()
                    .fill(Color.red.opacity(0.2))
                    .border(Color.red, width: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }

            // Existing redaction regions
            ForEach(regions) { region in
                if region.pageIndex == viewModel.state.currentPageIndex {
                    Rectangle()
                        .fill(Color.red.opacity(0.15))
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.red, style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                        )
                        .overlay {
                            HStack {
                                Image(systemName: "eye.slash")
                                    .font(.caption)
                                Text("Redact")
                                    .font(.caption)
                            }
                            .foregroundStyle(.red)
                        }
                        .frame(width: region.bounds.width, height: region.bounds.height)
                        .position(x: region.bounds.midX, y: region.bounds.midY)
                }
            }

            // Redaction list panel
            if viewModel.state.editorMode == .redact && !regions.isEmpty {
                VStack(alignment: .trailing) {
                    Spacer()
                    redactionListPanel
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
            }
        }
        .onChange(of: regions) { _, newValue in
            viewModel.security.redactionRegions = newValue
        }
    }

    private var redactionListPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pending Redactions (\(regions.count))")
                .font(.caption)
                .fontWeight(.medium)

            ForEach(regions) { region in
                HStack {
                    Image(systemName: "eye.slash")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text("Page \(region.pageIndex + 1)")
                        .font(.caption2)
                    Spacer()
                    Button {
                        regions.removeAll { $0.id == region.id }
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Button("Clear All") {
                    regions.removeAll()
                }
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding(10)
        .frame(width: 200)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4)
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func addRedactionRegion(from start: CGPoint, to end: CGPoint) {
        let rect = normalizedRect(from: start, to: end)
        guard rect.width > 5 && rect.height > 5 else { return }

        let region = RedactionRegion(
            bounds: rect,
            pageIndex: viewModel.state.currentPageIndex
        )
        regions.append(region)
    }
}
