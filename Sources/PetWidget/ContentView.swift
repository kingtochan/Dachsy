import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var viewModel = DogViewModel()
    @State private var dogImage: NSImage? = nil
    @State private var imageScale: CGFloat = 1.0
    @State private var showSettings = false
    @State private var chatInput: String = ""

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
                .padding(.bottom, 14)
        }
        .frame(width: 280, height: 430)
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
        HStack(spacing: 8) {
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
        }
        .frame(maxWidth: .infinity)
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
