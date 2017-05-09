extension Character {
    var isWhite: Bool {
        return [" ", "\t"].contains(self)
    }
}

enum Token {
    case lparen
    case rparen
    case quote
    case tick
    case comma
    case symbol(String)
    case string(String)
    case integer(Int)
    case float(Double)
}

extension Token {
    var id: String {
        switch (self) {
        case .lparen: return "("
        case .rparen: return ")"
        case .quote: return "'"
        case .tick: return "`"
        case .comma: return ","
        case .symbol: return "symbol"
        case .string: return "string"
        case .integer: return "integer"
        case .float: return "float"
        }
    }
}

let tokenMapping: [Character: Token] = [
  "(": .lparen,
  ")": .rparen,
  "'": .quote,
  "`": .tick,
  ",": .comma
]

class Lexer {
    let input: String
    var index: String.Index

    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }

    var peek: Character? {
        return index < input.endIndex ? input[index] : nil
    }

    func consume() {
        index = input.index(after: index)
    }

    func readSymbolOrNumber() -> String {
        var temp = ""
        while let char = peek, (!char.isWhite && tokenMapping[char] == nil) {
            temp.characters.append(char)
            consume()
        }
        return temp
    }

    func readString() -> String {
        var temp = ""
        var last: Character? = nil

        consume() // beginning "
        while let char = peek {
            if char == "\"" && last != "\\" {
                consume()
                break
            }

            temp.characters.append(char)
            consume()
            last = char
        }

        return temp
    }

    func nextToken() -> Token? {
        // eat whitespaces
        while let char = peek, char.isWhite {
            consume()
        }

        // exit if we have no more characters
        guard let char = peek else {
            return nil
        }

        if let token = tokenMapping[char] {
            consume()
            return token
        }

        if peek == "\"" {
            return .string(readString())
        }

        let temp = readSymbolOrNumber()
        if let i = Int(temp) {
            return .integer(i)
        } else if let d = Double(temp) {
            return .float(d)
        } else {
            return .symbol(temp)
        }
    }

    func tokenize() -> [Token] {
        var tokens = [Token]()

        while let token = nextToken() {
            tokens.append(token)
        }

        return tokens
    }
}
