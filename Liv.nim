let help = """
Usage:
  liv <file> [(-o | --output) <where>]
  liv (-h | --help)
  liv (-v | --version)

Options:
  -c --compile  Compile file.
  -h --help     Show this screen.
  -v --version  Show version.
  -o --output   Output to specific file.
"""

import docopt, parsecfg, json, src/lex

let args = docopt(help, version = loadConfig("./liv.nimble").getSectionValue("", "version"))

var output = ""
if args["--output"]:
    output = $args["output"]

if args["<file>"]:
    let file = $args["<file>"]
    for i in lex(file):
        echo i
