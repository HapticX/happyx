import
  happyx,
  components/task


var app = registerApp()


app.routes:
  "/":
    tDiv:
      class = "flex gap-2 p-2"
      component Task(text = "Send post to Reddit", isChecked = true)
      component Task(text = "Rest")
      component Task

app.start()
