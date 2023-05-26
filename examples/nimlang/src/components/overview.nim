import
  happyx,
  ../app_config


component Overview:
  `template`:
    tDiv(class = "flex bg-[{background}] pt-8 text-white justify-center items-center"):
      tDiv(class = "flex flex-col gap-4 px-4 lg:flex-row lg:w-3/4"):
        # General
        tDiv(class = "flex flex-col gap-2 lg:w-2/3"):
          tH1(class = "text-2xl md:text-3xl lg:text-4xl text-[{yellow}] transition-all"):
            "Efficient, expressive, elegant"
          tP(class = "text-lg"):
            "Nim is a statically typed compiled systems programming language."
            "It combines successful concepts from mature languages like Python, Ada and Modula."
          # Install and Playground buttons
          tDiv(class = "flex justify-center items-center p-2 gap-2 text-lg rounded-lg"):
            # Install
            tButton(class = "px-4 py-2 bg-[{yellow}] text-[{background}] hover:bg-opacity-90 active:bg-opacity-80 transition-all dutation-500"):
              "Install Nim 1.6.12"
              @click:
                route("/install")
            # Try it online
            tButton(class = "px-4 py-2 bg-[{gray}] text-[{background}] hover:bg-opacity-90 active:bg-opacity-80 transition-all dutation-500"):
              "Try it online"
              @click:
                route("/playground")
        # Code example
        tDiv(class = "flex flex-col lg:w-1/3")
