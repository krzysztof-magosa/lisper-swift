var lexer = Lexer(input: "(def-macro (x) '(print ,x))")
var data = lexer.tokenize()

print(data.tokens)
print(data.positions)
