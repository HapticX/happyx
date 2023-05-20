import
  ../src/happyx


mount A:
  "/":
    "Hello, world!"


mount B:
  mount "/a" -> A


appRoutes("app"):
  # Go to /a/
  mount "/a" -> A
  # Go to /b/a/
  mount "/b" -> B
