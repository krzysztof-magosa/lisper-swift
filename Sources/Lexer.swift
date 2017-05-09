extension Character {
    var isWhite: Bool {
        return [" ", "\t", "\n"].contains(self)
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

// when we compare tokens we just take care about their types
func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case (.lparen, .lparen):
        return true
    case (.rparen, .rparen):
        return true
    case (.quote, .quote):
        return true
    case (.tick, .tick):
        return true
    case (.comma, .comma):
        return true
    case (.symbol, .symbol):
        return true
    case (.string, .string):
        return true
    case (.integer, .integer):
        return true
    case (.float, .float):
        return true
    default:
        return false
    }
}

func !=(lhs: Token, rhs: Token) -> Bool {
    return !(lhs == rhs)
}

struct Position {
    let line: Int
    let column: Int
}

struct LexicalData {
    let tokens: [Token]
    let positions: [Position]
}

let tokenMapping: [Character: Token] = [
  "(": .lparen,
  ")": .rparen,
  "'": .quote,
  "`": .tick,
  ",": .comma
]

class Lexer {
    var tokens: [Token]
    var positions: [Position]
    var input: String
    var index: String.Index
    var line: Int
    var column: Int
    var position: Position?

    init(input: String) {
        self.tokens = []
        self.positions = []
        self.input = input
        self.index = input.startIndex
        self.line = 0
        self.column = 0
    }

    private var peek: Character? {
        return index < input.endIndex ? input[index] : nil
    }

    private func consume() {
        if peek == "\n" {
            self.line += 1
            self.column = 0
        } else {
            self.column += 1
        }

        index = input.index(after: index)
    }

    private func readSymbolOrNumber() -> String {
        var temp = ""
        while let char = peek, (!char.isWhite && tokenMapping[char] == nil) {
            temp.characters.append(char)
            consume()
        }
        return temp
    }

    private func readString() -> String {
        var temp = ""
        var last: Character? = nil

        consume() // beginning "
        while let char = peek {
            // if we hit into " and it was not escaped, it's end of string
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

    private func append(_ token: Token) {
        self.tokens.append(token)
        self.positions.append(self.position!)
    }

    func tokenize() -> LexicalData {
        while index < input.endIndex {
            // eat whitespaces
            while let char = peek, char.isWhite {
                consume()
            }

            // save position of token beginning
            self.position = Position(line: line, column: column)

            guard let char = peek else {
                break
            }

            if let token = tokenMapping[char] {
                // support for one-char tokens
                consume()
                append(token)
            } else if peek == "\"" {
                // consume string
                append(.string(readString()))
            } else {
                // try to guess what we read
                let temp = readSymbolOrNumber()
                if let i = Int(temp) {
                    append(.integer(i))
                } else if let d = Double(temp) {
                    append(.float(d))
                } else {
                    append(.symbol(temp))
                }
            }
        }

        return LexicalData(tokens: tokens, positions: positions)
    }
}
