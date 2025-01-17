import
  std/macros,
  std/strformat,
  ../base


proc getUserAgentDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
  statementList.insert(0, parseStmt"var userAgent = navigator.userAgent")


static:
  regDecorator("GetUserAgent", getUserAgentDecoratorImpl)
