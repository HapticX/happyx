# Package

description = "Macro-oriented asynchronous web-framework written with ♥"
author = "HapticX"
version = "4.6.1"
license = "MIT"
srcDir = "src"
installExt = @["nim"]
bin = @["happyx/hpx"]

# Deps

requires "nim >= 1.6.14"

# Std lib
requires "checksums >= 0.1.0"
# CLI
requires "cligen >= 1.6.14"
requires "illwill#2fe96f5c5a6e216e84554d92090ce3d47460667a"
# Regular expressions (only compile time)
requires "regex#head"
# alternative HTTP servers
requires "httpx >= 0.3.7"
requires "microasynchttpserver >= 0.11.0"
requires "httpbeast >= 0.4.2"
# Template engines
requires "nimja == 0.8.7"
# Websockets
requires "websocket >= 0.5.2"
requires "websocketx >= 0.1.2"
# Security
requires "nimcrypto >= 0.3.9"
