#[
  Provides Happyx main file
]#
import
  asyncdispatch,
  strtabs,
  strutils,
  strformat,
  logging,
  regex,
  core/[server]

when defined(httpx):
  import
    options,
    httpx
else:
  import asynchttpserver

export
  asyncdispatch,
  strtabs,
  strutils,
  strformat,
  logging,
  regex,
  server

when defined(httpx):
  export
    options,
    httpx
else:
  export asynchttpserver
