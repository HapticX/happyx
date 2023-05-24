import
  ../src/happyx


serve("127.0.0.1", 5000):
  var jsonNode = %*{"response": "success", "data": [1, 2, 3]}
  var html = buildHtml:
    "Hello, world"

  "/jsonTest":
    return jsonNode

  "/jsonTestWithKey":
    return jsonNode["data"]

  "/htmlTest":
    return html

  "/fileTest":
    return FileResponse("testdir" / "dudvmap.png")
