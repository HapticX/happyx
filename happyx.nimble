# Package

description = "Macro-oriented asynchronous web-framework written with ♥"
author = "HapticX"
version = "1.1.1"
license = "GNU GPLv3"
srcDir = "src"
installExt = @["nim"]
bin = @["hpx"]

# Deps

requires "nim >= 1.6.12"
# CLI
requires "cligen"
requires "illwill"
# Regular expressions
requires "regex"
# alternative HTTP servers
requires "httpx"
requires "microasynchttpserver"
# Template engines
requires "nimja"
# Websockets
requires "websocketx"
