import
  ../src/happyx


"/sugar" -> any:
  "You see this at any HTTP method at /sugar"


"/sugar/get" -> get:
  echo query~hello
  "You see this only at GET HTTP method at /sugar/get"


serve("127.0.0.1", 5000):
  "/":
    "Hello, world!"

  finalize:
    echo "bye"
