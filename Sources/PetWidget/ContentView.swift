import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = DogViewModel()
    @State private var dogImage: NSImage? = nil
    @State private var imageScale: CGFloat = 1.0
    @State private var showSettings = false
    @State private var chatInput: String = ""
    @State private var showPomodoroTimer: Bool = false
    @State private var pomodoroSetMinutes: Int = 25

    var body: some View {
        VStack(spacing: 0) {
            statBars
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)

            dogArea
                .padding(.bottom, 12)

            actionButtons
                .padding(.horizontal, 12)
                .padding(.bottom, 10)

            chatInputRow
                .padding(.horizontal, 12)
                .padding(.bottom, showPomodoroTimer ? 8 : 14)

            if showPomodoroTimer {
                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.horizontal, 12)
                pomodoroSection
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 280, height: showPomodoroTimer ? 540 : 430)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showPomodoroTimer)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.10, blue: 0.22),
                    Color(red: 0.08, green: 0.06, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .help("Settings")
            }
        }
        .onAppear { loadImage() }
        .onChange(of: viewModel.currentScenario) { _, _ in loadImage(bounce: true) }
        .onChange(of: viewModel.isPomodoroRunning) { _, isRunning in
            if !isRunning && viewModel.pomodoroTimeRemaining == nil && showPomodoroTimer {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    showPomodoroTimer = false
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Stats

    private var statBars: some View {
        VStack(spacing: 6) {
            StatBarView(icon: "🍖", label: "Hunger", value: viewModel.stats.hunger, color: .orange)
            StatBarView(icon: "💗", label: "Happy",  value: viewModel.stats.happiness, color: .pink)
            StatBarView(icon: "⚡", label: "Energy", value: viewModel.stats.energy, color: .yellow)
            StatBarView(icon: "🛁", label: "Clean",  value: viewModel.stats.cleanliness, color: .cyan)
        }
    }

    // MARK: - Dog Area

    private var dogArea: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                if let img = dogImage {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .scaleEffect(imageScale)
                        .onTapGesture { viewModel.pet() }
                        .help("Tap to pet!")
                } else {
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.white.opacity(0.3))
                }
                Spacer(minLength: 0)
            }
            .frame(height: 180)

            if let speech = viewModel.speechText {
                SpeechBubbleView(text: speech)
                    .frame(maxWidth: 220)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if viewModel.isLoadingResponse {
                SpeechBubbleView(text: "...")
                    .frame(maxWidth: 220)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.speechText)
        .animation(.easeInOut, value: viewModel.isLoadingResponse)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 6) {
            ActionButton(icon: "🍖", label: "Feed",
                         action: { viewModel.feed() },
                         disabled: viewModel.stats.energy <= 15)
            ActionButton(icon: "🎾", label: "Play",
                         action: { viewModel.play() },
                         disabled: viewModel.stats.energy <= 15)
            ActionButton(icon: "🛁", label: "Clean",
                         action: { viewModel.clean() },
                         disabled: viewModel.stats.energy <= 15)
            ActionButton(icon: "❤️", label: "Pet",
                         action: { viewModel.pet() },
                         disabled: viewModel.stats.energy <= 15)
            ActionButton(icon: "💼", label: "Work",
                         action: {
                             withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                 showPomodoroTimer.toggle()
                             }
                         },
                         disabled: viewModel.isWorkLocked)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pomodoro Section

    private var pomodoroSection: some View {
        VStack(spacing: 10) {
            if viewModel.isPomodoroRunning {
                VStack(spacing: 6) {
                    Text(formattedTime(viewModel.pomodoroTimeRemaining ?? 0))
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(viewModel.currentScenario == .focus ? "Deep focus 🔥" : "Studying hard 📚")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            } else {
                HStack {
                    Text("Focus duration")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Stepper(value: $pomodoroSetMinutes, in: 1...120) {
                        Text("\(pomodoroSetMinutes) min")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                Button {
                    viewModel.startPomodoro(totalSeconds: pomodoroSetMinutes * 60)
                } label: {
                    Text("Start Focus Session")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple.opacity(0.5))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.6), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Chat Input

    private var chatInputRow: some View {
        HStack(spacing: 8) {
            TextField("Say something to Dachsy...", text: $chatInput)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .onSubmit { sendChat() }

            Button(action: sendChat) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 13))
                    .foregroundColor(chatInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isInteracting || viewModel.stats.energy <= 10
                                     ? .white.opacity(0.3)
                                     : .white.opacity(0.85))
                    .padding(7)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(
                                chatInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isInteracting || viewModel.stats.energy <= 10 ? 0.06 : 0.18
                            ))
                    )
            }
            .buttonStyle(.plain)
            .disabled(chatInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isInteracting || viewModel.stats.energy <= 10)
        }
    }

    private func sendChat() {
        let msg = chatInput.trimmingCharacters(in: .whitespaces)
        guard !msg.isEmpty, !viewModel.isInteracting, viewModel.stats.energy > 10 else { return }
        viewModel.chat(message: msg)
        chatInput = ""
    }

    // MARK: - Image Loading

    private func loadImage(bounce: Bool = false) {
        dogImage = PetWidget.dogImage(for: viewModel.currentScenario)
        if bounce {
            imageScale = 0.85
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                imageScale = 1.0
            }
        }
    }
}
