import
  std/macros,
  std/strformat,
  std/tables,
  ../base


type
  RateLimitInfo* = object
    amount*: int
    update_at*: float


var rateLimits* {.threadvar.}: Table[string, RateLimitInfo]
rateLimits = initTable[string, RateLimitInfo]()


proc rateLimitDecoratorImpl(httpMethods: seq[string], routePath: string, statementList: NimNode, arguments: seq[NimNode]) =
  var
    fromAll = true
    perSecond = 60

  const intLits = { nnkIntLit..nnkInt64Lit }
  let boolean = [newLit(true), newLit(false)]

  for argument in arguments:
    if argument.kind == nnkExprEqExpr and argument[0] == ident"fromAll" and argument[1] in boolean:
      fromAll = argument[1].boolVal
    elif argument.kind == nnkExprEqExpr and argument[0] == ident"perSecond" and argument[1].kind in intLits:
      perSecond = argument[1].intVal.int

  statementList.insert(0, parseStmt(fmt"""
let key =
  when {not fromAll}:
    if hostname != "":
      hostname & "{routePath}"
    elif headers.hasKey("X-Forwarded-For"):
      headers["X-Forwarded-For"].split(",", 1)[0] & "{routePath}"
    elif headers.hasKey("X-Real-Ip"):
      headers["X-Real-Ip"] & "{routePath}"
    else:
      "{routePath}"
  else:
    "{routePath}"
if not rateLimits.hasKey(key):
  rateLimits[key] = RateLimitInfo(amount: 1, update_at: cpuTime())
elif cpuTime() - rateLimits[key].update_at < 1.0:
  inc rateLimits[key].amount
else:
  rateLimits[key].update_at = cpuTime()
  rateLimits[key].amount = 1

if rateLimits[key].amount > {perSecond}:
  var statusCode = 429
  return "Too many requests"
""")
  )

static:
  regDecorator("RateLimit", rateLimitDecoratorImpl)
