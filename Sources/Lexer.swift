extension Character {
    var isWhite: Bool {
        return [" ", "\t", "\n"].contains(self)
    }
}

enum TokenType {
    case lparen
    case rparen
    case modifier
    case symbol
    case string
    case integer
    case float
}

struct Position {
    let line: Int
    let column: Int
}

struct Token {
    let type: TokenType
    let payload: String
    let position: Position
}

let tokenMapping: [Character: TokenType] = [
  "(": .lparen,
  ")": .rparen,
  "'": .modifier,
  "`": .modifier,
  ",": .modifier
]

class Lexer {
    var tokens: [Token]
    var input: String
    var index: String.Index
    var line: Int
    var column: Int
    var position: Position

    init(input: String) {
        self.tokens = []
        self.input = input
        self.index = input.startIndex
        self.line = 0
        self.column = 0
        self.position = Position(line: self.line, column: self.column)
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

    private func append(type: TokenType, payload: String="") {
        self.tokens.append(
          Token(
            type: type,
            payload: payload,
            position: self.position
          )
        )
    }

    func tokenize() -> [Token] {
        while index < input.endIndex {
            // eat whitespaces
            while let char = peek, char.isWhite {
                consume()
            }

            // save position of token beginning
            self.position = Position(line: line, column: column)

            // break loop on EOF
            guard let char = peek else {
                break
            }

            if let type = tokenMapping[char] {
                // support for one-char tokens
                consume()
                append(type: type, payload: "\(char)")
            } else if peek == "\"" {
                // consume string
                append(type: .string, payload: readString())
            } else {
                // try to guess what we read
                let temp = readSymbolOrNumber()
                if let _ = Int(temp) {
                    append(type: .integer, payload: temp)
                } else if let _ = Double(temp) {
                    append(type: .float, payload: temp)
                } else {
                    append(type: .symbol, payload: temp)
                }
            }
        }

        return tokens
    }
}
