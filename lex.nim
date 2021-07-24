import json, error, strutils, tables, strformat, os

proc read(path: string): string =
    var file = path
    if not isAbsolute(path):
        file = joinPath(getCurrentDir(), path);
    if not fileExists(file):
        if fileExists(file & ".wump"):
            file = file & ".wump"
        else:
            echo "file not found"
    return readFile(file)

type TokenType = enum
    # symbols
    SLASH, LPAREN, RPAREN, LBRACE,
    RBRACE, COMMA, COLON, EQUAL, DOT

    # literals
    COMMAND, IDENTIFIER, STRING,
    INTEGER, FLOAT, BOOLEAN, OPERATOR

    # keywords
    IF, ELIF, ELSE, FOR, WHILE,
    LOOP, CONST, VAR, OP

    NEWLINE, TAB, EOF

let keywords = {"if": IF, "elif": ELIF, "else": ELSE, "for": FOR, "while": WHILE,
                "loop": LOOP, "const": CONST, "var": VAR, "op": OP}.toTable
let opchars = ["!", "@", "$", "%", "^", "&", "*", "=",
               "+", "-", "|", "~", "<", ">", "/"]

const nums = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

proc lex*(file: string): seq[JsonNode] =
    var source = read(file)
    var tokens: seq[JsonNode]
    var col = 0
    var lines = source.split('\n')
    var start = 0
    var current = 0
    var line = 1

    proc isAtEnd(): bool =
        return (current >= source.len)

    proc increment() =
        current = current + 1
        col = col + 1

    proc match(expected: char): bool =
        if isAtEnd(): return false
        if source[current] != expected: return false
        increment()
        return true

    proc next(): char =
        increment()
        return source[current - 1]

    proc peek(): char =
        if isAtEnd(): return '\0'
        return source[current]

    proc peekNext(): char =
        if ((current + 1) >= source.len): return '\0'
        return source[current + 1]

    proc addToken(kind: TokenType, literal: string) =
        let text = source[start ..< current]
        tokens.add(%* {
            "kind": kind,
            "lexeme": text,
            "line": line,
            "col": col,
            "value": literal
        })

    proc str() =
        let startline = line
        while peek() != '"' and not isAtEnd():
            if peek() == '\n': line = line + 1
            increment()

        if isAtEnd():
            error(%* {
                "message": "unterminated string",
                "code": lines[startline - 1],
                "file": file,
                "line": startline,
                "col": col - (current - start) + 1
            })

        increment()
        addToken(STRING, source[start - 1 .. current - 1])

    proc num() =
        while isDigit(peek()): increment()

        var f = false
        if peek() == '.' and isDigit(peekNext()):
            increment()
            f = true

            while isDigit(peek()): increment()

        if f:
            addToken(FLOAT, source[start ..< current])
        else:
            addToken(INTEGER, source[start ..< current])

    proc isAlpha(c: char): bool =
        if isAlphaAscii(c) or c == '_': return true
        return false

    proc isID(c: char): bool =
        if isAlpha(c) or isDigit(c): return true
        return false

    proc identifier() =
        while isID(peek()): increment()

        if keywords.hasKey(source[start ..< current]):
            #addToken(keywords[source[start .. current]], %* {})
            addToken(keywords[source[start ..< current]], source[start ..< current])
        else:
            addToken(IDENTIFIER, source[start ..< current])

    proc isop(c: char): bool =
        return (opchars.find($c) != -1)

    proc op() =
        while isop(peek()): increment()
        addToken(OPERATOR, source[start ..< current])

    proc scanToken() =
        let c = next()
        case c:
            of '(': addToken(LPAREN, "(")
            of ')': addToken(RPAREN, ")")
            of '{': addToken(LBRACE, "{")
            of '}': addToken(RBRACE, "}")
            of ',': addToken(COMMA, ",")
            of ':': addToken(COLON, ":")
            of '.': addToken(DOT, ".")
            of '=': addToken(EQUAL, "=")
            of '\\': addToken(SLASH, "\\")
            of '#':
                if peek() == '#':
                    increment()
                    while peek() != '#' and peekNext() != '#' and not isAtEnd():
                        if peek() == '\n': line = line + 1
                        increment()
                    increment()
                    increment()
                else:
                    while peek() != '\n' and not isAtEnd(): increment()
            of '?':
                if peek() == '[':
                    increment()
                    while peek() != ']' and not isAtEnd(): increment()
                    increment()
                    addToken(COMMAND, source[start ..< current])
                else:
                    error(%* {
                        "message": fmt"unexpected symbol `{c}`",
                        "code": lines[line - 1],
                        "file": file,
                        "line": line,
                        "col": col
                    })
            of '"': str()
            of ' ':
                discard
            of '\n':
                line = line + 1
                col = 0
            else:
                if isDigit(c):
                    num()
                elif isAlpha(c):
                    identifier()
                elif isop(c):
                    op()
                else:
                    error(%* {
                        "message": fmt"unexpected symbol `{c}`",
                        "code": lines[line - 1],
                        "file": file,
                        "line": line,
                        "col": col
                    })

    proc scanTokens(): seq[JsonNode] =
        while not isAtEnd():
            start = current
            scanToken()
        addToken(EOF, "")
        return tokens
    return scanTokens()
