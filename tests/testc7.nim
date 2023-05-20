import
  ../src/happyx


mount A:
  "/":
    return {"response": "success"}


mount B:
  mount "/a" -> A


serve("127.0.0.1", 5000):
  # Go to /b/a/
  mount "/b" -> B
  # You can also go to /a/
  mount "/a" -> A
