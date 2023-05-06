import ../../src/happyx


serve("127.0.0.1", 5000):
  get "/":
    "Hello, world!"
