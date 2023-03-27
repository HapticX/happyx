import
  unittest,
  ../src/happyx


proc main =
  var server = newServer("127.0.0.1", 5000)

  server.routes:
    echo "Hello, world!"
    
    route("/"):
      echo "Hello world!"
  
  server.start()

main()
