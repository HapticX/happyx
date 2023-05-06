import
  happyx,
  components/task


var
  inputText = ""
  tasks = @[
    ("Send post to Reddit", true),
    ("Rest", false),
  ]


appRoutes("app"):
  "/":
    tDiv(class = "flex justify-center items-center w-screen h-screen bg-gray-100"):
      tDiv(class = "flex flex-col gap-4 px-8 py-4 bg-white rounded-2xl drop-shadow-xl"):
        # Create a new task
        tDiv(class = "flex justify-between gap-2 items-center"):
          input:
            id = "input"
            class = "rounded-full bg-gray-100 px-4 py-2 outline-0 border-0"
            placeholder = "Enter task ..."
            @input:
              let inp = document.getElementById("input")
              inputText = $inp.value
          button:
            class = "flex text-xl font-semibold w-10 h-10 justify-center items-center rounded-full cursor-pointer bg-green-300"
            "+"
            @click:
              if inputText.len > 0:
                tasks.add((inputText, false))
                application.router()
              inputText = ""
        tDiv(class = "flex flex-col gap-2"):
          for (t, c) in tasks:
            component Task(text = t, isChecked = c)
