{.define: happyxSkipServeMain.}
import std/json, ../src/happyx
type options_encoding* = enum
  encodingA, encodingB
model DataProcessRequest:
  data: string = ""
  storage: options_encoding = encodingA
  xtemplate: string = ""
serve "127.0.0.1", 0:
  get "/": return %*{"ok": true}
echo openApiJson()["components"]["schemas"]
