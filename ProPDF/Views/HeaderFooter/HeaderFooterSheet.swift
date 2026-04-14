import SwiftUI
import AppKit

struct HeaderFooterSheet: View {
    let viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var config = HeaderFooterConfig()
    @State private var isApplying = false

    var body: some View {
        HStack(spacing: 0) {
            // Settings
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Header & Footer")
                        .font(.title3)
                        .fontWeight(.semibold)

                    // Header fields
                    GroupBox {
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Left")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Header Left", text: $config.headerLeft)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Center")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Header Center", text: $config.headerCenter)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Header Right", text: $config.headerRight)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    } label: {
                        Text("Header")
                    }

                    // Footer fields
                    GroupBox {
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Left")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Footer Left", text: $config.footerLeft)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Center")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Footer Center", text: $config.footerCenter)
                                        .textFieldStyle(.roundedBorder)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    TextField("Footer Right", text: $config.footerRight)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    } label: {
                        Text("Footer")
                    }

                    // Template tokens
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available tokens:")
                                .font(.caption)
                                .fontWeight(.medium)

                            HStack(spacing: 8) {
                                tokenButton("<<page>>", description: "Page number")
                                tokenButton("<<total>>", description: "Total pages")
                            }
                            HStack(spacing: 8) {
                                tokenButton("<<date>>", description: "Current date")
                                tokenButton("<<bates>>", description: "Bates number")
                            }
                        }
                    } label: {
                        Text("Template Tokens")
                    }

                    Divider()

                    // Font settings
                    FontPickerButton(fontName: $config.fontName, fontSize: $config.fontSize)
                    ColorPickerButton(title: "Text Color", color: $config.color)

                    Divider()

                    // Margins
                    GroupBox {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Top:").font(.caption).frame(width: 50, alignment: .trailing)
                                TextField("", value: $config.margins.top, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder).frame(width: 60)
                                Text("Bottom:").font(.caption).frame(width: 50, alignment: .trailing)
                                TextField("", value: $config.margins.bottom, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder).frame(width: 60)
                            }
                            HStack {
                                Text("Left:").font(.caption).frame(width: 50, alignment: .trailing)
                                TextField("", value: $config.margins.left, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder).frame(width: 60)
                                Text("Right:").font(.caption).frame(width: 50, alignment: .trailing)
                                TextField("", value: $config.margins.right, formatter: NumberFormatter())
                                    .textFieldStyle(.roundedBorder).frame(width: 60)
                            }
                        }
                    } label: {
                        Text("Margins (points)")
                    }

                    // Page numbering
                    HStack {
                        Text("Start page number at:")
                            .font(.caption)
                        TextField("", value: $config.startPageNumber, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                    }

                    Divider()

                    // Bates numbering
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Enable Bates Numbering", isOn: $config.useBatesNumbering)
                                .font(.caption)

                            if config.useBatesNumbering {
                                HStack {
                                    Text("Prefix:").font(.caption)
                                    TextField("", text: $config.batesPrefix)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                    Text("Suffix:").font(.caption)
                                    TextField("", text: $config.batesSuffix)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                                HStack {
                                    Text("Start:").font(.caption)
                                    TextField("", value: $config.batesStartNumber, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                    Text("Digits:").font(.caption)
                                    TextField("", value: $config.batesDigits, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                }
                            }
                        }
                    } label: {
                        Text("Bates Numbering")
                    }

                    Divider()

                    // Page range
                    PageRangeSelector(pageRange: $config.pageRange, totalPages: viewModel.pageCount)

                    // Buttons
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Apply") {
                            applyHeaderFooter()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .disabled(isApplying)
                    }
                }
                .padding()
            }
            .frame(width: 380)

            Divider()

            // Preview
            HeaderFooterPreviewView(
                config: config,
                pdfDocument: viewModel.pdfDocument,
                pageIndex: viewModel.state.currentPageIndex,
                totalPages: viewModel.pageCount
            )
            .frame(minWidth: 300)
        }
        .frame(width: 720, height: 650)
        .overlay {
            if isApplying {
                ProgressOverlay(message: "Applying header & footer...")
            }
        }
    }

    private func tokenButton(_ token: String, description: String) -> some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(token, forType: .string)
        } label: {
            VStack(spacing: 1) {
                Text(token)
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(4)
        }
        .buttonStyle(.bordered)
        .help("Click to copy \(token) to clipboard")
    }

    private func applyHeaderFooter() {
        isApplying = true

        Task {
            viewModel.headerFooter.config = config
            await viewModel.headerFooter.apply()
            await MainActor.run {
                isApplying = false
                dismiss()
            }
        }
    }
}
