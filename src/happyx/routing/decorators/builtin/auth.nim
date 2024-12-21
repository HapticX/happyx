import
  std/macros,
  std/strformat,
  ../base


proc authBasicDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
  statementList.insert(0, parseStmt"""
var (username, password) = ("", "")
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {"response": "failure", "reason": "You should to use Basic authorization!"}
else:
  (username, password) = block:
    let code = headers["Authorization"].split(" ")[1]
    let decoded = base64.decode(code).split(":", 1)
    (decoded[0], decoded[1])"""
    )
  

proc authBearerJwtDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
  let variableName = if arguments.len > 0: arguments[0] else: ident"jwtToken"
  statementList.insert(0, parseStmt(fmt"""
var {variableName}: TableRef[system.string, claims.Claim]
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {{"response": "failure", "reason": "You should to be authorized!"}}
else:
  if headers["Authorization"].startsWith("Bearer "):
    {variableName} = headers["Authorization"][7..^1].toJWT.claims
  else:
    var statusCode = 401
    return {{"response": "failure", "reason": "You should to be authorized!"}}""")
    )
  

proc authJwtDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
  let variableName = if arguments.len > 0: arguments[0] else: ident"jwtToken"
  statementList.insert(0, parseStmt(fmt"""
var {variableName}: TableRef[system.string, claims.Claim]
if not headers.hasKey("Authorization"):
  var statusCode = 401
  return {{"response": "failure", "reason": "You should to be authorized!"}}
else:
  {variableName} = headers["Authorization"].toJWT.claims""")
    )


static:
  regDecorator("AuthBasic", authBasicDecoratorImpl)
  regDecorator("AuthBearerJWT", authBearerJwtDecoratorImpl)
  regDecorator("AuthJWT", authJwtDecoratorImpl)
