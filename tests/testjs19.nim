# Import HappyX
import
  ../src/happyx


# Declare application with ID "app"
appRoutes "app":
  "/page1":
    tButton:
      "goto page2"
      @click:
        echo 2
        route("/page2")
    tA:
      "page2 bis"
      href:="#/page2"
    # !debugCurrent
  "/page2":
    tButton:
      "goto page1"
      @click:
        echo 1
        route("/page1")
    tA:
      "page1 bis"
      href:="#/page1"
    # !debugCurrent
