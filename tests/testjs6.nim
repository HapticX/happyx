import
  ../src/happyx


"/sugar" -> build:
  "You see this at /sugar"


"/sugar/get" -> build:
  "You see this at /sugar/get"


appRoutes("app"):
  "/":
    "Hello, world!"

  finalize:
    echo "bye"
