import Foundation
import AppKit
import SwiftUI

// MARK: - AI Service (Supports Claude & Ollama)

actor AIService {
    static func generateResponse(provider: String, apiKey: String, ollamaModel: String, scenario: DogScenario, stats: DogStats) async -> String {
        
        let systemPrompt = """
        You are Dachsy, an adorable sausage dog (dachshund) desktop pet with a big personality.
        Respond with short, expressive, dog-like reactions. Keep responses under 60 characters.
        Use dog sounds (woof, bork, arf), *actions in asterisks*, and 1-2 emojis.
        Current state: \(scenario.rawValue).
        Hunger: \(Int(stats.hunger))%, Happiness: \(Int(stats.happiness))%, Energy: \(Int(stats.energy))%, Cleanliness: \(Int(stats.cleanliness))%.
        """
        
        if provider == "Ollama" {
            return await fetchOllama(model: ollamaModel, system: systemPrompt, scenario: scenario)
        } else {
            guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
                return scenario.responses.randomElement() ?? "Woof!"
            }
            return await fetchClaude(apiKey: apiKey, system: systemPrompt, scenario: scenario)
        }
    }
    
    // --- OLLAMA LOGIC ---
    private static func fetchOllama(model: String, system: String, scenario: DogScenario) async -> String {
        guard let url = URL(string: "http://localhost:11434/api/chat") else {
            return scenario.responses.randomElement() ?? "Woof!"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15 // Ollama might take a bit longer to generate
        
        let body: [String: Any] = [
            "model": model.isEmpty ? "llama3" : model,
            "stream": false,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": "React to this moment as Dachsy!"]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return scenario.responses.randomElement() ?? "Woof!"
        }
        request.httpBody = httpBody
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Ollama Error: \(error.localizedDescription)")
            // Fall through to default
        }
        return scenario.responses.randomElement() ?? "Woof!"
    }
    
    // --- CLAUDE LOGIC ---
    private static func fetchClaude(apiKey: String, system: String, scenario: DogScenario) async -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return scenario.responses.randomElement() ?? "Woof!"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 8

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 80,
            "system": system,
            "messages": [["role": "user", "content": "React to this moment as Dachsy!"]]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return scenario.responses.randomElement() ?? "Woof!"
        }
        request.httpBody = httpBody

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Claude Error: \(error.localizedDescription)")
        }
        return scenario.responses.randomElement() ?? "Woof!"
    }
}

// MARK: - Dog ViewModel

@MainActor
final class DogViewModel: ObservableObject {
    @Published var stats = DogStats()
    @Published var currentScenario: DogScenario = .default
    @Published var speechText: String? = nil
    @Published var isInteracting = false
    @Published var isLoadingResponse = false

    // New Settings Variables
    @Published var aiProvider: String = UserDefaults.standard.string(forKey: "aiProvider") ?? "Claude"
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""
    @Published var ollamaModel: String = UserDefaults.standard.string(forKey: "ollamaModel") ?? "llama3.2:1b"

    private var decayTimer: Timer?
    private var speechTimer: Timer?

    init() {
        updateScenario()
        startDecayTimer()
    }

    deinit {
        decayTimer?.invalidate()
        speechTimer?.invalidate()
    }

    // MARK: - Timer

    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.decayStats()
            }
        }
    }

    private func decayStats() {
        if currentScenario == .sleeping {
            stats.energy = min(100, stats.energy + 8)
            stats.happiness = max(0, stats.happiness - 1)
            
            if stats.energy < 100 {
                return 
            }
        } else {
            stats.hunger = max(0, stats.hunger - 4)
            stats.happiness = max(0, stats.happiness - 2)
            stats.energy = max(0, stats.energy - 2)
            stats.cleanliness = max(0, stats.cleanliness - 1.5)
        }
        if !isInteracting {
            updateScenario()
        }
    }

    func updateScenario() {
        currentScenario = stats.currentScenario
    }

    // MARK: - Actions

    func feed() {
        guard !isInteracting else { return }
        guard stats.energy > 10 else { speak(text: "Zzz... later... 💤"); return }
        stats.hunger = min(100, stats.hunger + 35)
        stats.happiness = min(100, stats.happiness + 8)
        performInteraction(scenario: .feeding, duration: 2.0)
    }

    func play() {
        guard !isInteracting else { return }
        guard stats.energy > 15 else {
            speak(text: "Too tired... need sleep 😴")
            return
        }
        stats.happiness = min(100, stats.happiness + 28)
        stats.energy = max(0, stats.energy - 22)
        stats.hunger = max(0, stats.hunger - 8)
        stats.cleanliness = max(0, stats.cleanliness - 5)
        performInteraction(scenario: .playing, duration: 2.5)
    }

    func clean() {
        guard !isInteracting else { return }
        stats.cleanliness = min(100, stats.cleanliness + 45)
        stats.happiness = min(100, stats.happiness + 12)
        performInteraction(scenario: .happy, duration: 2.0)
    }

    func pet() {
        guard !isInteracting else { return }
        guard stats.energy > 10 else { speak(text: "Zzz... 💤"); return }
        stats.happiness = min(100, stats.happiness + 18)
        performInteraction(scenario: .excited, duration: 2.0)
    }

    private func performInteraction(scenario: DogScenario, duration: Double) {
        isInteracting = true
        currentScenario = scenario
        fetchAndSpeak(scenario: scenario)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isInteracting = false
            self?.updateScenario()
        }
    }

    // MARK: - Speech

    private func fetchAndSpeak(scenario: DogScenario) {
        // Capture current settings safely for the background task
        let provider = aiProvider
        let key = apiKey
        let model = ollamaModel
        let capturedStats = stats
        
        isLoadingResponse = true
        Task {
            let text = await AIService.generateResponse(
                provider: provider,
                apiKey: key,
                ollamaModel: model,
                scenario: scenario,
                stats: capturedStats
            )
            self.isLoadingResponse = false
            self.speak(text: text)
        }
    }

    func speak(text: String) {
        speechTimer?.invalidate()
        speechText = text
        speechTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.4)) {
                    self?.speechText = nil
                }
            }
        }
    }

    // MARK: - Settings

    func saveSettings() {
        UserDefaults.standard.set(aiProvider, forKey: "aiProvider")
        UserDefaults.standard.set(apiKey, forKey: "claudeApiKey")
        UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel")
    }
}