var lexer = Lexer(input: "'x")
var tokens = lexer.tokenize()
var parser = Parser(input: tokens)
parser.parse()
