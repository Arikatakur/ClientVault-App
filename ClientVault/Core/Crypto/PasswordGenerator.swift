import Foundation

/// Cryptographically secure password generator using `SystemRandomNumberGenerator`.
enum PasswordGenerator {

    struct Options {
        var length: Int = 20
        var includeUppercase: Bool = true
        var includeLowercase: Bool = true
        var includeNumbers: Bool = true
        var includeSymbols: Bool = true
    }

    enum Strength { case weak, fair, strong, veryStrong }

    static func generate(options: Options = Options()) -> String {
        var charset = ""
        if options.includeLowercase { charset += "abcdefghijklmnopqrstuvwxyz" }
        if options.includeUppercase { charset += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if options.includeNumbers   { charset += "0123456789" }
        if options.includeSymbols   { charset += "!@#$%^&*()-_=+[]{}|;:,.<>?" }

        guard !charset.isEmpty else { return "" }

        let chars = Array(charset)
        var rng = SystemRandomNumberGenerator()
        return String((0..<options.length).map { _ in
            chars[Int.random(in: 0..<chars.count, using: &rng)]
        })
    }

    static func strength(of password: String) -> Strength {
        var score = 0
        if password.count >= 8  { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        if password.count >= 20 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil    { score += 1 }
        let symbols = CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:,.<>?")
        if password.unicodeScalars.contains(where: symbols.contains) { score += 2 }

        switch score {
        case ..<4:  return .weak
        case 4..<6: return .fair
        case 6..<8: return .strong
        default:    return .veryStrong
        }
    }
}
