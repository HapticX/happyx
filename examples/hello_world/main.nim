import ../../src/happyx


serve("127.0.0.1", 5000):
  server.routes:
    get "/":
      req.answer "Hello, world!"
