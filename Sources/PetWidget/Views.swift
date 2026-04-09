import SwiftUI
import AppKit

// MARK: - Stat Bar

struct StatBarView: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color

    private var fillColor: Color {
        if value < 25 { return .red }
        if value < 50 { return .orange }
        return color
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 13))
                .frame(width: 18)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(fillColor)
                        .frame(width: geo.size.width * CGFloat(value / 100), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: value)
                }
            }
            .frame(height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 46, alignment: .leading)
        }
    }
}

// MARK: - Speech Bubble

struct SpeechBubbleView: View {
    let text: String

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    )
                // Tail
                Triangle()
                    .fill(Color.white)
                    .frame(width: 16, height: 8)
                    .offset(y: -1)
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 8, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + 8, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(disabled
                          ? Color.white.opacity(0.08)
                          : Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

// MARK: - Settings Sheet

struct SettingsView: View {
    @ObservedObject var viewModel: DogViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var draftAlwaysOnTop: Bool = false
    @State private var draftProvider: String = "Claude"
    @State private var draftKey: String = ""
    @State private var draftOllamaModel: String = "llama3"

    let providers = ["Claude", "Ollama"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.3))

            // Always on Top Toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Always on Top")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Keep window above all other windows")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Toggle("", isOn: $draftAlwaysOnTop)
                    .labelsHidden()
            }

            Divider().background(Color.white.opacity(0.3))

            // AI Provider Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Provider")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Picker("", selection: $draftProvider) {
                    ForEach(providers, id: \.self) {
                        Text($0).tag($0)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Dynamic Fields based on selection
            if draftProvider == "Claude" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude API Key")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    SecureField("sk-ant-...", text: $draftKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ollama Model Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Make sure Ollama is running this model locally.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    TextField("e.g. llama3, phi3, mistral", text: $draftOllamaModel)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.7))
                Button("Save") {
                    viewModel.alwaysOnTop = draftAlwaysOnTop
                    viewModel.aiProvider = draftProvider
                    viewModel.apiKey = draftKey
                    viewModel.ollamaModel = draftOllamaModel
                    viewModel.saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(Color(red: 0.12, green: 0.12, blue: 0.18))
        .onAppear {
            draftAlwaysOnTop = viewModel.alwaysOnTop
            draftProvider = viewModel.aiProvider
            draftKey = viewModel.apiKey
            draftOllamaModel = viewModel.ollamaModel
        }
    }
}
