import
  std/macros,
  ../core/constants


when enableHttpBeast:
  import ../private/macro_utils


proc handleWebsockets*(wsClosedConnection: NimNode): tuple[wsStmtList, insertWsList: NimNode] =
  ## This is helpful function to work with websockets
  let wsClientI = ident"wsClient"
  var
    insertWsList = newStmtList()
    wsDelStmt = newStmtList(
      newCall(
        "del",
        ident"wsConnections",
        newCall("find", ident"wsConnections", wsClientI))
    )
  when enableHttpx or enableBuiltin:
    wsDelStmt.add(newCall("close", wsClientI))
  when enableHttpBeast:
    let asyncFd = newDotExpr(newDotExpr(ident"req", ident"client"), ident"AsyncFD")
    let wsStmtList = newStmtList(
      newLetStmt(
        ident"headers",
        newCall("get", newDotExpr(ident"req", ident"headers"))
      ),
      newCall("forget", ident"req"),
      newCall("register", asyncFd),
      newLetStmt(ident"socket", newCall("newAsyncSocket", asyncFd)),
      newMultiVarStmt(
        [wsClientI, ident"error"],
        newCall("await", newCall("verifyWebsocketRequest", ident"socket", ident"headers", newLit(""))),
        true
      ),
      newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
        newCall("isNil", wsClientI),
        newStmtList(newCall("close", ident"socket"))
      ), newNimNode(nnkElse).add(newStmtList(
        newCall("add", ident"wsConnections", wsClientI),
        newCall("__wsConnect", wsClientI),
        newNimNode(nnkWhileStmt).add(newLit(true), newStmtList(
          newMultiVarStmt(
            [ident"opcode", ident"wsData"],
            newCall("await", newCall("readData", wsClientI)),
            true
          ),
          newNimNode(nnkTryStmt).add(
            # TRY
            newStmtList(
              newNimNode(nnkIfStmt).add(newNimNode(nnkElifBranch).add(
                newCall("==", ident"opcode", newDotExpr(ident"Opcode", ident"Close")),
                newStmtList(
                  when enableDebug:
                    newStmtList(
                      newCall("echo", newLit"Socket closed"),
                      wsDelStmt,
                      newCall("__wsClosed", wsClientI)
                    )
                  else:
                    if wsClosedConnection.len == 0:
                      wsDelStmt
                    else:
                      newStmtList(wsDelStmt, newCall("__wsClosed", wsClientI)),
                  newNimNode(nnkBreakStmt).add(newEmptyNode())
                )
              )),
              insertWsList
            # OTHER WS ERROR
            ), newNimNode(nnkExceptBranch).add(
              when enableDebug:
                newStmtList(
                  newCall(
                    "echo",
                    newCall("fmt", newLit"Unexpected socket error: {getCurrentExceptionMsg()}")
                  ),
                  wsDelStmt,
                  newCall("__wsError", wsClientI)
                )
              else:
                newStmtList(wsDelStmt, newCall("__wsError", wsClientI))
            )
          )
        ))
      ))),
    )
  else:
    let wsStmtList = newStmtList(
      newLetStmt(wsClientI, newCall("await", newCall("newWebSocket", ident"req"))),
      newCall("add", ident"wsConnections", wsClientI),
      newNimNode(nnkTryStmt).add(
        newStmtList(
          newCall("__wsConnect", wsClientI),
          newNimNode(nnkWhileStmt).add(
            newCall("==", newDotExpr(wsClientI, ident"readyState"), ident"Open"),
            newStmtList(
              newLetStmt(ident"wsData", newCall("await", newCall("receiveStrPacket", wsClientI))),
              insertWsList
            )
          )
        ),
        newNimNode(nnkExceptBranch).add(
          ident"WebSocketClosedError",
          when enableDebug:
            newStmtList(
              newCall(
                "echo", newCall("fmt", newLit"Socket closed: {getCurrentExceptionMsg()}")
              ),
              wsDelStmt,
              newCall("__wsClosed", wsClientI)
            )
          else:
            newStmtList(wsDelStmt, newCall("__wsClosed", wsClientI))
        ),
        newNimNode(nnkExceptBranch).add(
          ident"WebSocketProtocolMismatchError",
          when enableDebug:
            newStmtList(
              newCall(
                "echo",
                newCall("fmt", newLit"Socket tried to use an unknown protocol: {getCurrentExceptionMsg()}")
              ),
              wsDelStmt,
              newCall("_wsMismatchProtocol", wsClientI)
            )
          else:
            newStmtList(wsDelStmt, newCall("__wsMismatchProtocol", wsClientI))
        ),
        newNimNode(nnkExceptBranch).add(
          ident"WebSocketError",
          when enableDebug:
            newStmtList(
              newCall(
                "echo",
                newCall("fmt", newLit"Unexpected socket error: {getCurrentExceptionMsg()}")
              ),
              wsDelStmt,
              newCall("__wsError", wsClientI)
            )
          else:
            newStmtList(wsDelStmt, newCall("__wsError", wsClientI))
        )
      )
    )
  return (wsStmtList, insertWsList)

