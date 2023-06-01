import
  happyx,
  components/[chat]


appRoutes("app"):
  "/":
    tDiv(class = "p-4"):
      component Chat
