enum X {
    case x(String)
    case y(String)
}

let x = X.x("hello")
let y = X.y("world")

let z = String(describing: x)
print(z)

var lexer = Lexer(input: "'x")
var tokens = lexer.tokenize()
var parser = Parser(input: tokens)
parser.parse()
