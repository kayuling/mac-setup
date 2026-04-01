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
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                }

                VStack(spacing: 6) {
                    Text("Homebrew Required")
                        .font(.system(size: 20, weight: .bold))
                    Text("MacSetup uses Homebrew to install apps.\nPaste the command below into Terminal to get started.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.top, 36)
            .padding(.horizontal, 32)

            // Command box
            VStack(alignment: .leading, spacing: 8) {
                Text("Install Command")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 0) {
                    Text(installCommand)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                            .frame(width: 44, height: 44)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .help("Copy command")
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                StepRow(number: 1, text: "Copy the command above")
                StepRow(number: 2, text: "Open Terminal (\u{2318} Space \u{2192} \"Terminal\")")
                StepRow(number: 3, text: "Paste and press Return")
                StepRow(number: 4, text: "Click \"Check Again\" when done")
            }
            .padding(.horizontal, 32)
            .padding(.top, 22)

            Spacer()

            // Actions
            Divider()
            HStack {
                Button("Skip for Now") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.system(size: 13))

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
                            ProgressView().scaleEffect(0.65).frame(width: 14, height: 14)
                            Text("Checking...")
                        }
                    } else {
                        Text("Check Again")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isChecking)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 500, height: 460)
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.8), in: Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
    }
}
