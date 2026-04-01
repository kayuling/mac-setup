import SwiftUI
import AppKit

struct BrewOnboardingView: View {
    let onDismiss: () -> Void

    @State private var isChecking = false
    @State private var copied = false

    private let installCommand = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    var body: some View {
        VStack(spacing: 0) {
            // Header with sophisticated graphics
            ZStack {
                LinearGradient(
                    colors: [Color.orange.opacity(0.15), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .shadow(color: .orange.opacity(0.3), radius: 20, y: 10)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                    
                    VStack(spacing: 4) {
                        Text("Homebrew Required")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                        
                        Text("The missing package manager for macOS")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 40)

            // Content
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("What is Homebrew?", systemImage: "info.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.orange)
                    
                    Text("Homebrew is a powerful command-line tool that allows MacSetup to automate the installation of your favorite applications and developer tools.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
                
                // Command Area
                VStack(alignment: .leading, spacing: 12) {
                    Text("RUN THIS COMMAND IN TERMINAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.tertiary)
                        .tracking(1)

                    HStack(spacing: 0) {
                        Text(installCommand)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.05))
                        
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(installCommand, forType: .string)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                copied = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            ZStack {
                                if copied {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundStyle(.secondary)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(width: 48, height: 48)
                            .background(Color.black.opacity(0.1))
                        }
                        .buttonStyle(.plain)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                }
                .padding(.horizontal, 40)
            }
            .padding(.top, 20)

            Spacer()

            // Action Bar
            HStack(spacing: 16) {
                Button("Later") {
                    onDismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.system(size: 13, weight: .bold))

                Spacer()

                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "terminal.fill")
                        Text("Open Terminal")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.05), in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    isChecking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isChecking = false
                        if BrewChecker.isBrewInstalled {
                            onDismiss()
                        }
                    }
                } label: {
                    ZStack {
                        if isChecking {
                            ProgressView().scaleEffect(0.6)
                                .brightness(1)
                        } else {
                            Text("I've installed it")
                        }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(isChecking)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 540, height: 620)
        .background(.background)
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
