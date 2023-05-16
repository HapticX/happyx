## Provides HappyX exceptions
import
  strutils,
  macros


type
  InvalidComponentSyntaxDefect* = object of Defect
  InvalidPathParamDefect* = object of Defect
  InvalidServeRouteDefect* = object of Defect


proc throwDefect*(defect: typedesc, msg: string, lineInfo: LineInfo) =
  var lines = msg.split('\n')
  raise newException(
    defect,
    "\n\x1b[31mUnhandled exception " & $defect &
    fmt" in {lineInfo.filename} at {lineInfo.line}:{lineInfo.column}" &
    "\n  " & lines.join("\n  ") & "\e[0m"
  )
