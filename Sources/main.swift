var lexer = Lexer(input: "'(- -5.1 10.0)")
var tokens = lexer.tokenize()

var parser = Parser(input: tokens)
var nodes = try parser.parse()
dump(nodes)
// var parser = Parser(input: lexicalData.tokens)
// var data = try! parser.parseAll()
