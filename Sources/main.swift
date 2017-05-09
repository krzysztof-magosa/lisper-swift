var lexer = Lexer(input: "(- -5.1 10.0)")
var data = lexer.tokenize()

print(data.tokens)
print(data.positions)
