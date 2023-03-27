#[
  Provides working with server
]#
import
  macros,
  asynchttpserver,
  asyncdispatch


type
  Server* = object
    address*: string
    port*: int


proc newServer*(address: string, port: int): Server =
  ## Initializes a new Server object
  Server(address: address, port: port)


template routes*(server: Server, stmtList: untyped): untyped =
  proc serverFunc() {.async, gcsafe.} =
    var serverInstance = newAsyncHttpServer()

    proc handleRequest(req: Request) {.async.} =
      `stmtList`
      let headers = {"Content-type": "text/plain; charset=utf-8"}
      await req.respond(Http200, "Hello World", headers.newHttpHeaders())

    serverInstance.listen(Port(server.port), server.address)
    let p = serverInstance.getPort
    echo "test this with: curl localhost:" & $p.uint16 & "/"
    while true:
      if serverInstance.shouldAcceptRequest():
        await serverInstance.acceptRequest(handleRequest)
      else:
        # too many concurrent connections, `maxFDs` exceeded
        # wait 500ms for FDs to be closed
        await sleepAsync(500)


template start*(server: Server): untyped =
  waitFor serverFunc()


macro route*(path: string, stmtList: untyped): untyped =
  discard
