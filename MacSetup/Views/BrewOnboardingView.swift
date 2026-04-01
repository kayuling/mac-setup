import SwiftUI
import AppKit

struct BrewOnboardingView: View {
    let onDismiss: () -> Void

    @State private var isChecking = false
    @State private var copied = false

    private let installCommand = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("Homebrew Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("MacSetup uses Homebrew to install apps automatically.\nPaste the command below into Terminal to get started.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 36)
            .padding(.horizontal, 32)

            // Command box
            VStack(alignment: .leading, spacing: 8) {
                Text("Install Homebrew")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 0) {
                    Text(installCommand)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor))

                    Divider()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(installCommand, forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                            .font(.system(size: 13))
                            .foregroundStyle(copied ? .green : .secondary)
                            .frame(width: 44)
                    }
                    .buttonStyle(.plain)
                    .help("Copy command")
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)

            // Steps
            VStack(alignment: .leading, spacing: 10) {
                StepRow(number: "1", text: "Copy the command above")
                StepRow(number: "2", text: "Open Terminal (⌘ Space → \"Terminal\")")
                StepRow(number: "3", text: "Paste and press Return, follow the prompts")
                StepRow(number: "4", text: "Click \"Check Again\" when done")
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)

            Spacer()

            // Actions
            Divider()
            HStack {
                Button("Skip for Now") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                } label: {
                    Label("Open Terminal", systemImage: "terminal")
                }
                .buttonStyle(.bordered)

                Button {
                    isChecking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isChecking = false
                        if BrewChecker.isBrewInstalled {
                            onDismiss()
                        }
                    }
                } label: {
                    if isChecking {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                            Text("Checking…")
                        }
                    } else {
                        Text("Check Again")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isChecking)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 480, height: 440)
    }
}

private struct StepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Color.accentColor, in: Circle())

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
        }
    }
}
