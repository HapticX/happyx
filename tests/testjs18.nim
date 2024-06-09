import ../src/happyx


template thunkHtml(body: untyped): proc(): TagRef =
  proc(): TagRef = buildHtml:
    body

template thunkHtmls(body: untyped): seq[proc(): TagRef] =
  block:
    var res: seq[proc(): TagRef]
    template html(b: untyped) =
      res.add:
        proc(): TagRef = buildHtml:
          b
    body
    res

let htmlProcs = thunkHtmls:
  html:
    tSpan: "front"
  html:
    tSpan: "back"

let htmlTags = buildHtmls:
  html:
    tSpan: "right"
  html:
    tSpan: "left"

component FormatProcHtml:
  p: (proc (): TagRef) # parentheses needed in avoid "nested statements" error
  html:
    em(style="color:blue"):
      {self.p()}

component FormatTagHtml:
  t: TagRef
  html:
    em(style="color:blue"):
      {self.t.val}

appRoutes("app"):
  "/":
    for i in 1..5:
      tDiv:{$htmlProcs[0]()}
      FormatProcHtml(htmlProcs[1])
    for i in 1..5:
      tDiv:{$htmlTags[0]}
      FormatTagHtml(htmlTags[1])
