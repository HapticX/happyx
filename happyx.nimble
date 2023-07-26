# Package

description = "Macro-oriented asynchronous web-framework written with ♥"
author = "HapticX"
version = "1.10.2"
license = "MIT"
srcDir = "src"
installExt = @["nim"]
bin = @["hpx"]

# Deps

requires "nim >= 1.6.14"
# CLI
requires "cligen"
requires "illwill"
# Regular expressions
requires "regex"
# alternative HTTP servers
requires "httpx"
requires "microasynchttpserver"
requires "httpbeast"
# Template engines
requires "nimja"
# Websockets
requires "websocket"
requires "websocketx"
