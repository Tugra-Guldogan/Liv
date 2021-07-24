import json, strutils, terminal

proc error*(e: JsonNode) =
    setForegroundColor(fgRed)
    stdout.write("error")
    setForegroundColor(fgDefault)
    if e.hasKey("type"):
        stdout.write(": " & e["type"].getStr())
    stdout.write(": ")
    if e.hasKey("message"):
        stdout.write(e["message"].getStr())
    if e.hasKey("code"):
        stdout.write("\n" & e["code"].getStr())
    if e.hasKey("col"):
        stdout.write("\n")
        if e.hasKey("highlight"):
            stdout.write(' '.repeat(e["col"].getInt() - 1) & '^'.repeat(e["highlight"].getInt()))
        else:
            if e["col"].getInt() == 1:
                setForegroundColor(fgRed)
                stdout.write("^")
                setForegroundColor(fgDefault)
            else:
                setForegroundColor(fgRed)
                stdout.write(' '.repeat(e["col"].getInt() - 1) & "^")
                setForegroundColor(fgDefault)
    stdout.write("\n")
    if e.hasKey("file"):
        stdout.write("in ")
        setForegroundColor(fgCyan)
        stdout.write(e["file"].getStr())
        setForegroundColor(fgDefault)
        if e.hasKey("line"):
            stdout.write(":")
            setForegroundColor(fgCyan)
            stdout.write($e["line"].getInt())
            setForegroundColor(fgDefault)
            if e.hasKey("col"):
                stdout.write(":")
                setForegroundColor(fgCyan)
                stdout.write($e["col"].getInt())
                setForegroundColor(fgDefault)
        stdout.write("\n")
    quit(1)
