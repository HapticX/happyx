## Provides HappyX exceptions
import
  strutils,
  macros


type
  InvalidComponentSyntaxDefect* = object of Defect
  InvalidPathParamDefect* = object of Defect
  InvalidServeRouteDefect* = object of Defect
  InvalidModelSyntaxDefect* = object of Defect
  InvalidCORSSyntaxDefect* = object of Defect
  MountDefect* = object of Defect


proc throwDefect*(defect: typedesc, msg: string, lineInfo: LineInfo) =
  var lines = msg.split('\n')
  raise newException(
    defect,
    "\n\x1b[31mUnhandled exception " & $defect &
    fmt" in {lineInfo.filename}({lineInfo.line}, {lineInfo.column})" &
    "\n  " & lines.join("\n  ") & "\e[0m"
  )
