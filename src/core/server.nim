#[
  Provides working with server
]#
import
  macros,
  strutils,
  asynchttpserver,
  asyncdispatch,
  json,
  uri


type
  Server* = object
    address*: string
    port*: int
    instance*: AsyncHttpServer


proc newServer*(address: string = "127.0.0.1", port: int = 5000): Server =
  ## Initializes a new Server object
  Server(address: address, port: port, instance: newAsyncHttpServer())


template start*(server: Server): untyped =
  waitFor server.instance.serve(Port(server.port), handleRequest, server.address)


template answer*(req: Request, message: string, code: HttpCode = Http200): untyped =
  ## Answers to the request
  ## 
  ## Arguments:
  ##   `req: Request`: An instance of the Request type, representing the request that we are responding to.
  ##   `message: string`: The message that we want to include in the response body.
  ##   `code: HttpCode = Http200`: The HTTP status code that we want to send in the response.
  ##                               This argument is optional, with a default value of Http200 (OK).
  await req.respond(
    code,
    message,
    {
      "Content-type": "text/plain; charset=utf-8"
    }.newHttpHeaders()
  )


func parseQuery*(path: string): JsonNode =
  ## Parses query and retrieves
  result = newJObject()
  for i in path.split('&'):
    let splitted = i.split('=')
    result[splitted[0]] = %*splitted[1]


macro routes*(server: Server, body: untyped): untyped =
  ## You can create routes with this marco
  var
    stmtList = newStmtList()
  
  for statement in body:
    if statement.kind == nnkCall:
      # "/...": statement list
      if statement[1].kind == nnkStmtList:
        echo statement[0]
      # func("/..."): statement list
      else:
        echo statement[1]

  quote do:
    proc handleRequest(req: Request) {.async, gcsafe.} =
      let
        query = parseQuery(req.url.query)
        path = req.url.path
      echo req.reqMethod
      echo path
      echo query
      `stmtList`
