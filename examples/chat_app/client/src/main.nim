import
  ../../../../src/happyx,
  ./components/[chat, message]


appRoutes "app":
  "/":
    tDiv(class = "p-4"):
      component Chat
