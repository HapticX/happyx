# Package

description = "Macro-oriented asynchronous web-framework written with ♥"
author = "HapticX"
version = "2.5.1"
license = "MIT"
srcDir = "src"
installExt = @["nim"]
bin = @["happyx/hpx"]

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
# Cryptographic
requires "nimcrypto"
# Language bindings
requires "nimpy"
