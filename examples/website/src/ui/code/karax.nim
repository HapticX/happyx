const
  karaxHelloWorld* = """include karax / prelude

proc createDom(): VNode =
  result = buildHtml(tdiv):
    text "Hello World!"

setRenderer createDom
"""
  happyxVsKaraxHelloWorld1* = """import happyx

appRoutes "app":
  "/":
    "Hello, world!"
"""
  happyxVsKaraxHelloWorld2* = """import happyx

proc createDom(): TagRef =
  result = buildHtml:
    "Hello, world!"

appRoutes "app":
  "/":
    createDom
"""
  karaxEventModel* = """include karax / prelude

var lines: seq[kstring] = @[]

proc createDom(): VNode =
  result = buildHtml(tdiv):
    button:
      text "Say hello!"
      proc onclick(ev: Event; n: VNode) =
        lines.add "Hello simulated universe"
    for x in lines:
      tdiv:
        text x

setRenderer createDom
"""
  happyxVsKaraxEventModel* = """import happyx

var lines = remember newSeq[string]()

appRoutes "app":
  "/":
    tButton:
      "Say hello!"
      @click:
        lines->add("Hello simulated universe")
    for x in lines:
      tDiv:
        {x}
"""
  happyxVsKaraxEventModel1* = """import happyx

appRoutes "app":
  "/":
    tButton:
      "Say hello!"
      @click:
        console.log(ev)  # ev is event
        console.log("Hello, world!")
      @click(event):
        console.log(event)  # event is event
        console.log("Goodbye, world!")
"""
