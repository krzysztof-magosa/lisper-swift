# LISPer - LISP dialect implemented in Swift

## Built-in functions
### (+ ...)
Adds all arguments sequentially.  
Number of arguments: any.  
Returns: NUMBER.  

```
LISPer> (+)
0
LISPer> (+ 2 2 6)
10
LISPer> (+ 2.0 2.0)
4.0
```

### (- A B ...)
Substracts all arguments sequentially.  
Number of arguments: 2 or more.  
Returns: NUMBER.  

```
LISPer> (- 10 5 5)
0
LISPer> (- 10.0 4 6)
0.0
```

### (/ A B ...)
Divides all arguments sequentially.  
Number of arguments: 2 or more.  
Returns: NUMBER.  

```
LISPer> (/ 10 5)
2
LISPer> (/ 10 2.0)
5.0
```

### (* A B ...)
Multiplies all arguments sequentially.  
Number of arguments: 2 or more.  
Returns: NUMBER.  

```
LISPer> (* 2 2 2)
8
LISPer> (* 2 3 4.0)
24.0
```

### (rem A B)
Returns remainder of division of A over B.  
Number of arguments: 2.  
Returns: NUMBER.  

```
LISPer> (rem 10 3)
1
LISPer> (rem -10 3)
-1
```

### (= A ...)
Checks if all arguments are the same numbers.  
Number of arguments: 1 or more.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (= 1)
t
LISPer> (= 1 1.0)
t
```

### (< A ...)
Checks if numbers are sequentially greater than previous one.  
Number of arguments: 1 or more.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (< 5)
t
LISPer> (< 1 2 3 4 5)
t
LISPer> (< 1 2 3 3)
nil
LISPer> (< 2 1)
nil
```

### (<= A ...)
Checks if numbers are sequentially greater or equal than previous one.  
Number of arguments: 1 or more.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (<= 5)
t
LISPer> (<= 1 2 3 4 5 5)
t
LISPer> (<= 2 1)
nil
```

### (> A ...)
Checks if numbers are sequentially less than previous one.  
Number of arguments: 1 or more.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (> 5 4 3 2 1)
t
LISPer> (> 5 4 3 3)
nil
LISPer> (> 1 2)
nil
```

### (>= A ...)
Checks if numbers are sequentially less or equal than previous one.  
Number of arguments: 1 or more.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (>= 5 4 3 3)
t
LISPer> (>= 5 4 3)
t
LISPer> (>= 2 3)
nil
```

### (equal A B ...)
Checks if all arguments are structurally similar.  
Number of arguments: 2 or more.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (equal 2 2)
t
LISPer> (equal (+ 2 2) (+ 2 2))
t
LISPer> (equal (list 1 2 3) (list 1 2 3))
t
LISPer> (equal (list 1 2 3) (list 3 2 1))
nil
LISPer> (equal 'a 'a)
t
LISPer> (equal nil ())
t
LISPer> (equal nil 'nil)
t
LISPer> (equal nil '())
t
LISPer> (equal "hello" "hello")
t
```

### (exists A)
Checks if symbol is available within scope.  
Number of arguments: 1.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (exists hello)
nil
LISPer> (define hello "Hello world!")
hello
LISPer> (exists hello)
t
```

### (null A)
Checks if argument is equal to `nil`.  
Number of arguments: 1.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (null nil)
t
LISPer> (null 'nil)
t
LISPer> (null ())
t
LISPer> (null t)
nil
LISPer> (null 5)
nil
```

### (atom A)
Checks if argument is atom.  
Number of arguments: 1.  
Returns: `t` if true, `nil` otherwise.  

```
LISPer> (atom 'x)
t
LISPer> (atom "X")
t
LISPer> (atom nil)
t
LISPer> (atom (list))
t
LISPer> (atom (list 1 2 3))
nil
LISPer> (atom 5.0)
t
LISPer> (atom 1)
t
```

### (join A B ...)
Joins all arguments together.  
Number of arguments: 2 or more.  
Returns: LIST.  

```
LISPer> (join (list 1 2 3) (list 4 5 6))
(1 2 3 4 5 6)
LISPer> (join (list 1 2 3) nil)
(1 2 3)
LISPer> (join nil nil)
nil
```

### (cons A B ...)
Returns list created from head (A) and rest (B).  
Number of arguments: 2 or more.  
Returns: LIST.  
Remarks: LISPer does not support pairs, therefore list is always returned.  

```
LISPer> (cons 1 (list 2 3))
(1 2 3)
LISPer> (cons 1 2)
(1 2)
LISPer> (cons 1 nil)
(1)
```

### (car A)
Returns head of list.  
Number of arguments: 1.  
Returns: ANY.  

```
LISPer> (car (list 1 2 3 4 5))
1
LISPer> (car (list (list 1 2 3) (list 4 5 6)))
(1 2 3)
LISPer> (car (list))
nil
```

### (cdr A)
Returns rest of list.  
Number of arguments: 1.  
Returns: LIST.  

```
LISPer> (cdr (list 1 2 3 4 5))
(2 3 4 5)
LISPer> (cdr (list (list 1 2 3) (list 4 5 6)))
((4 5 6))
LISPer> (cdr (list))
nil
```

### (if A B C)
In case A is true evaluates B, otherwise C (which defaults to nil).  
Number of arguments: 2 or 3.  
Returns: ANY.  

```
LISPer> (if t 1 2)
1
LISPer> (if t 1)
1
LISPer> (if nil 1)
nil
LISPer> (if nil 1 2)
2
```

### (print A)
Prints LISP representation of argument.  
Number of arguments: 1.  
Returns: ANY.  

```
LISPer> (print 1)
1
1
LISPer> (print 1.0)
1.0
1.0
LISPer> (print "hello world")
"hello world"
"hello world"
LISPer> (print '(list 1 2 3))
(list 1 2 3)
(list 1 2 3)
```

### (quote A or 'A)
Returns argument without evaluating it.  
Number of arguments: 1.  
Returns: ANY.  

```
LISPer> '1
1
LISPer> '(1 2 3)
(1 2 3)
LISPer> 'x
x
LISPer> '((+ 2 2) (+ 2 2))
((+ 2 2) (+ 2 2))
```

### (quasiquote or `A)
Works similar to quote but allows part of argument to be evaluated (using `,` prefix).  
Number of arguments: 1.  
Returns: ANY.  

```
LISPer> `1
1
LISPer> `(1 2 3)
(1 2 3)
LISPer> `x
x
LISPer> `(,(+ 2 2) (+ 2 2))
(4 (+ 2 2))
```

### (list ...)
Creates list consisted of arguments.  
Number of arguments: any.  
Returns: LIST.  

```
LISPer> (list)
nil
LISPer> (list 1 2 3)
(1 2 3)
```

### (begin ...)
Evaluates all arguments and returns value of last one.  
Number of arguments: any.  
Returns: ANY.  

```
LISPer> (begin)
nil
LISPer> (begin 1)
1
LISPer> (begin 1 2 3)
3
LISPer> (begin 1 2 (+ 1 2))
3
LISPer> (begin (print "a") (print "b") (print "c"))
"a"
"b"
"c"
"c"
```

### (define A B)
Defines variable A in current scope and sets its value to B.  
Number of arguments: 2.  
Returns: SYMBOL.  

```
LISPer> (define x 5)
x
LISPer> x
5
```

### (lambda (A ...) B)
Creates lambda which takes parameters `A ...` and its body is `B`.  
Number of arguments: 2.  
Returns: LAMBDA.  

```
LISPer> (lambda (a b) (+ a b))
(lambda (a b) (+ a b))
LISPer> (define sum (lambda (a b) (+ a b)))
sum
LISPer> (sum 2 2)
4
LISPer> (define p (lambda (a b) (print b)))
p
LISPer> (p (print "test") 5)
"test"
5
5
LISPer> (define pp (lambda (x) (print x)))
pp
LISPer> (pp (+ 1 2))
3
3
```

### (macro (A ...) B)
Create macro which takes parameters `A ...` and its body is `B`.  
Number of arguments: 2.  
Returns: MACRO.  

```
LISPer> (define sum (macro (a b) (+ a b)))
sum
LISPer> (sum 2 2)
4
LISPer> (define p (macro (a b) (print b)))
p
LISPer> (p (print "test") 5)
5
5
LISPer> (define pp (macro (x) (print x)))
pp
LISPer> (pp (+ 1 2))
(+ 1 2)
3
```

### (to-symbol A)
Converts string to symbol.  
Number of arguments: 1.  
Returns: SYMBOL.  

```
LISPer> (to-symbol "1+")
1+
LISPer>
LISPer> (call (to-symbol "1+") 1)
2
```

## Standard macros
### (def-macro A (B ...) C)
Defines macro A with arguments (B ...) and body C.

```
LISPer> (def-macro hello (a) (print a))
hello
LISPer> (hello "hello")
"hello"
"hello"
```

### (def-lambda A (B ...) C)
Defines lambda A with arguments (B ...) and body C.

```
LISPer> (def-lambda hello (a) (print a))
hello
LISPer> (hello "hello")
"hello"
"hello"
```

### (1+ A)
Returns successor of A (number greater by 1).  

```
LISPer> (1+ 10)
11
LISPer> (1+ -20)
-19
```

### (1- A)
Returns predecessor of A (number lesser by 1).  

```
LISPer> (1- 10)
9
LISPer> (1- -20)
-21
```

### (map A B)
Returns list created by applying function A on list B.  

```
LISPer> (map '1+ (list 0 1 2 3 4))
(1 2 3 4 5)

LISPer> (map 'print (list 0 1 2 3 4))
0
1
2
3
4
(0 1 2 3 4)
LISPer> (map 'null (list 1 nil 2 nil 3))
(nil t nil t nil)
```

### (filter A B)
Filters list B using function A.  

```
LISPer> (filter 'null (list 1 nil 2 nil))
(nil nil)
LISPer> (filter 'odd (list 1 2 3 4 5))
(1 3 5)
LISPer> (filter 'atom (list 1 (list 2 3) 4))
(1 4)
```

### (reverse A)
Reverses list A.  

```
LISPer> (reverse (list 5 4 3 2 1))
(1 2 3 4 5)
```

### (head A B)
Returns first A elements from list B.  

```
LISPer> (head 1 (list 1 2 3 4 5))
(1)
LISPer> (head 2 (list 1 2 3 4 5))
(1 2)
```

### (tail A B)
Returns last A elements from list B.  

```
LISPer> (tail 1 (list 1 2 3 4 5))
(5)
LISPer> (tail 2 (list 1 2 3 4 5))
(4 5)
```

### (not A)
Returns `t` if A is `nil`, `nil` otherwise.  

```
LISPer> (not t)
nil
LISPer> (not nil)
t
LISPer> (not 100)
nil
```

### (even A)
Returns `t` if A is even, `nil` otherwise.  

```
LISPer> (even 1)
nil
LISPer> (even 2)
t
LISPer> (even -2)
t
```

### (odd A)
Returns `t` if A is odd, `nil` otherwise.  
```
LISPer> (odd 1)
t
LISPer> (odd 2)
nil
LISPer> (odd -3)
t
```
