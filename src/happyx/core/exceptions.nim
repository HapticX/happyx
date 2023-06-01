## # HappyX Exceptions 🧨
## 
## Describes all defect types that can be thrown
## 
import
  strutils,
  macros


type
  HpxPathParamDefect* = object of Defect  ## Throws when path params is wrong
  HpxServeRouteDefect* = object of Defect  ## Throws when server routes syntax is invalid
  HpxAppRouteDefect* = object of Defect  ## Throws when server routes syntax is invalid
  HpxCorsDefect* = object of Defect  ## Throws when regCORS syntax is invalid
  HpxComponentDefect* = object of Defect  ## Throws when component declaration syntax is invalid
  HpxModelSyntaxDefect* = object of Defect  ## Throws when model syntax declaaration is invalid
  HpxMountDefect* = object of Defect  ## Throws when mounting syntax is invalid
  HpxSyntaxSugarDefect* = object of Defect  ## Throws on syntax sugar errors
  HpxBuildHtmlDefect* = object of Defect  ## Throws when buildHtml syntax is invalid
  HpxBuildStyleDefect* = object of Defect  ## Throws when buildStyle syntax is invalid
  HpxBuildJsDefect* = object of Defect  ## Throws when buildJs syntax is invalid


proc throwDefect*(defect: typedesc, msg: string, lineInfo: LineInfo) =
  ## Throws HappyX errors
  var lines = msg.split('\n')
  raise newException(
    defect,
    "\n\x1b[31mUnhandled exception " & $defect &
    fmt" in {lineInfo.filename}({lineInfo.line}, {lineInfo.column})" &
    "\n  " & lines.join("\n  ") & "\e[0m"
  )
