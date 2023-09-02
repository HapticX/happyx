# Package

description = "Macro-oriented asynchronous web-framework written with ♥"
author = "HapticX"
version = "2.9.0"
license = "MIT"
srcDir = "src"
installExt = @["nim"]
bin = @["happyx/hpx"]

# Deps

requires "nim >= 1.6.14"
# CLI
requires "cligen >= 1.6.14"
requires "illwill >= 0.3.1"
# Regular expressions
requires "regex#199e696a1b0e0db72e2e5a657926e5b944e6ae2d"
# alternative HTTP servers
requires "httpx >= 0.3.7"
requires "microasynchttpserver >= 0.11.0"
requires "httpbeast >= 0.4.2"
# Template engines
requires "nimja >= 0.8.7"
# Websockets
requires "websocket >= 0.5.2"
requires "websocketx >= 0.1.2"
# Security
requires "nimcrypto >= 0.3.9"
requires "oauth >= 0.10"
# Language bindings
requires "nimpy >= 0.2.0"
