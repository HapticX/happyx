import
  ../src/happyx


"/sugar" -> any:
  return "You see this at any HTTP method at /sugar"


"/sugar/get" -> get:
  return "You see this only at GET HTTP method at /sugar/get"


serve("127.0.0.1", 5000):
  "/":
    return "Hello, world!"
