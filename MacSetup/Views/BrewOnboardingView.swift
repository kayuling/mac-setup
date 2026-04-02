import SwiftUI
import AppKit

struct BrewOnboardingView: View {
    let onDismiss: () -> Void

    @State private var isChecking = false
    @State private var copied = false
    @State private var animateIn = false

    private let installCommand = #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    var body: some View {
        ZStack {
            // Background Mesh Gradient
            MeshGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Content
                ScrollView {
                    VStack(spacing: 40) {
                        headerSection
                        stepsSection
                        commandSection
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)
            }
            
            // Fixed Bottom Bar
            VStack {
                Spacer()
                actionBar
            }
        }
        .frame(width: 680, height: 740)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 20, y: 10)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .rotationEffect(.degrees(animateIn ? 0 : -20))
            }
            
            VStack(spacing: 8) {
                Text("Welcome to MacSetup")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                
                Text("We need Homebrew to handle the heavy lifting.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            StepView(number: 1, title: "Copy Command", description: "Grab the installation script below.", isComplete: copied)
            StepView(number: 2, title: "Open Terminal", description: "Standard macOS utility for commands.", isComplete: false)
            StepView(number: 3, title: "Paste & Execute", description: "Follow prompts in the terminal window.", isComplete: false)
        }
        .padding(.horizontal, 60)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 30)
    }

    // MARK: - Command

    private var commandSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("INSTALLATION SCRIPT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                if copied {
                    Text("Copied to clipboard!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            HStack(spacing: 0) {
                Text(installCommand)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(installCommand, forType: .string)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label("Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 24)
                        .frame(height: 60)
                        .background(copied ? Color.green : Color.primary)
                        .foregroundStyle(copied ? .white : (Color(nsColor: .windowBackgroundColor)))
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        }
        .padding(.horizontal, 60)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 40)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 20) {
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "terminal.fill")
                    Text("Launch Terminal")
                }
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            Button {
                isChecking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isChecking = false
                    if BrewChecker.isBrewInstalled {
                        withAnimation { onDismiss() }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if isChecking {
                        ProgressView().scaleEffect(0.7).brightness(1)
                    } else {
                        Text("I'm Ready")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: .orange.opacity(0.4), radius: 15, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(isChecking)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
        )
    }
}

// MARK: - Supporting Views

struct MeshGradientBackground: View {
    @State private var t: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            let date = timeline.date.timeIntervalSince1970
            let angle = Angle(radians: date * 0.2)
            
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 600, height: 600)
                    .offset(x: cos(date * 0.3) * 100, y: sin(date * 0.4) * 100)
                    .blur(radius: 100)
                
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 500, height: 500)
                    .offset(x: sin(date * 0.5) * 150, y: cos(date * 0.3) * 150)
                    .blur(radius: 120)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .offset(x: cos(date * 0.4) * 200, y: sin(date * 0.2) * 200)
                    .blur(radius: 100)
            }
        }
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.primary.opacity(0.05))
                    .frame(width: 40, height: 40)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
