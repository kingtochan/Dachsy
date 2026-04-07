import Foundation
import AppKit

// MARK: - Dog Scenarios

enum DogScenario: String, CaseIterable {
    case `default` = "default"
    case dirty = "dirty"
    case excited = "excited"
    case feeding = "feeding"
    case happy = "happy"
    case hungry = "hungry"
    case playing = "playing"
    case sad = "sad"
    case sleeping = "sleeping"
    case tired = "tired"

    var responses: [String] {
        switch self {
        case .default:
            return ["*wags tail*", "Woof!", "I'm here! 🐾", "*looks around curiously*", "Bork?"]
        case .dirty:
            return ["I need a bath! 🛁", "*smells funny*", "Woof... I'm all muddy!", "Clean me please! 🥺"]
        case .excited:
            return ["WOOF WOOF! 🎉", "This is the BEST day ever!", "*zooms around the room*", "YAY YAY YAY! 🐾"]
        case .feeding:
            return ["NOM NOM NOM! 😋", "*chews happily*", "Delicious!! More?", "FOOD IS LIFE! 🍖"]
        case .happy:
            return ["*happy wiggle* 😊", "Life is sooo good!", "I love you! 🐾", "Woof woof! ❤️"]
        case .hungry:
            return ["My tummy is empty... 🥺", "*puppy eyes* Food?", "FOOD? Please?! 🍖", "Hungry... so hungry..."]
        case .playing:
            return ["This is SO fun! 🎾", "*chases tail excitedly*", "Let's play more!!", "FETCH FETCH FETCH! 🎾"]
        case .sad:
            return ["*whimpers softly* 😢", "Pay attention to me...", "I miss you so much...", "*droopy ears* 😔"]
        case .sleeping:
            return ["Zzz... 💤", "*snores softly*", "Not now... sleepy...", "Zzzzzzz 💤"]
        case .tired:
            return ["*big yawn* 😴", "So... sleepy...", "Need nap soon...", "*droopy eyes*"]
        }
    }

}

// MARK: - Dog Stats

struct DogStats {
    var hunger: Double = 80       // 0-100, decreases over time
    var happiness: Double = 80    // 0-100, decreases over time
    var energy: Double = 80       // 0-100, play costs energy, sleep restores
    var cleanliness: Double = 80  // 0-100, decreases slowly

    var currentScenario: DogScenario {
        if energy <= 10 { return .sleeping }
        if energy <= 25 { return .tired }
        if hunger <= 20 { return .hungry }
        if cleanliness <= 20 { return .dirty }
        if happiness >= 88 { return .excited }
        if happiness >= 65 { return .happy }
        if happiness <= 25 { return .sad }
        return .default
    }
}

// MARK: - Image Loading

func dogImage(for scenario: DogScenario) -> NSImage {
    // .app bundle: images are in Contents/Resources/sausage_dog_scenarios/
    if let url = Bundle.main.url(forResource: scenario.rawValue, withExtension: "png", subdirectory: "sausage_dog_scenarios"),
       let img = NSImage(contentsOf: url) {
        return img
    }
    // SPM development build: Bundle.module points to .build resources
    if let url = Bundle.module.url(forResource: scenario.rawValue, withExtension: "png", subdirectory: "sausage_dog_scenarios"),
       let img = NSImage(contentsOf: url) {
        return img
    }
    return NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: nil) ?? NSImage()
}
