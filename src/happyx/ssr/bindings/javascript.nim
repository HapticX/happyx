import
  regex,
  std/tables,
  ../types,
  ./session


export regex

var
  servers*: seq[Server] = @[]
  requests* = newTable[string, Request]()
  wsClients* = newTable[string, node_types.WebSocket]()

proc registerWsClient*(wsClient: node_types.WebSocket): string {.gcsafe.} =
  {.gcsafe.}:
    result = genSessionId()
    wsClients[result] = wsClient

proc unregisterWsClient*(wsClientId: string) {.gcsafe.} =
  {.gcsafe.}:
    wsClients.del(wsClientId)

proc registerRequest*(req: Request): string {.gcsafe.} =
  {.gcsafe.}:
    result = genSessionId()
    requests[result] = req

proc unregisterRequest*(reqId: string) {.gcsafe.} =
  {.gcsafe.}:
    requests.del(reqId)
