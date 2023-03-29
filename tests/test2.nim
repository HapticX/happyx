import
  strformat,
  ../src/happyx


proc main =
  var server = newServer()

  server.routes:
    notfound:
      req.answer "Oops! Not found!"
  
  server.start()

main()
