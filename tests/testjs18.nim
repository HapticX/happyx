import ../src/happyx

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


htmlTags[1].eventListener("click"):
  echo 1
htmlTags[1].click()

let promise = withPromise res:
  withTimeout 1000, t:
    clearTimeout(t)
    echo "timeout"
    {.emit: "res(true)".}


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
