import
  ../src/happyx,
  ./components/[hello_world]


serve("127.0.0.1", 5000):
  "/":
    return buildHtml:
      component HelloWorld(counter = 24)
      component HelloWorld(counter = 36)
      component HelloWorld(counter = 48)
      component HelloWorld(counter = 60)
      component HelloWorld(counter = 72)
