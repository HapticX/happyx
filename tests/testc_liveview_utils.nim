import
  std/httpcore,
  std/unittest,
  ../src/happyx/ssr/utils


suite "LiveView / HTTP utils":
  test "headerHasToken splits comma-separated Connection values":
    let h = newHttpHeaders([("Connection", "keep-alive, Upgrade")])
    check headerHasToken(h, "connection", "upgrade")
    check not headerHasToken(h, "connection", "close")

  test "headerHasToken matches Upgrade websocket token":
    let h = newHttpHeaders([("Upgrade", "websocket")])
    check headerHasToken(h, "upgrade", "websocket")
