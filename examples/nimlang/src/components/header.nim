import
  happyx,
  ../app_config,
  header_button


component Header:
  mobileSidebar: bool = false

  `template`:
    # Main header
    tDiv(class = "fixed flex w-full items-center px-4 h-12 lg:justify-around justify-between bg-[{backHeader}] transition-all"):
      # Logo container
      tDiv(class = "flex items-center h-full px-2 cursor-pointer hover:bg-white/10 active:bg-white/20 transition-colors duration-500"):
        img(src = "public/logo.svg", class="h-6")
        @click:
          route("/")
      # Header desktop buttons
      tDiv(class = "hidden lg:flex h-full"):
        tDiv(class = "flex h-full"):
          component HeaderButton(text = "Blog", path = "/blog")
          component HeaderButton(text = "Features", path = "/features")
          component HeaderButton(text = "Download", path = "/download")
          component HeaderButton(text = "Documentation", path = "/docs")
          component HeaderButton(text = "Forum", path = "/forum")
          component HeaderButton(text = "Donate", path = "/donate")
          component HeaderButton(text = "Source", path = "/source")
      # Header mobile buttons
      tDiv(class = "flex lg:hidden text-white h-full"):
        tButton:
          "☰"
          @click:
            self.mobileSidebar = not self.mobileSidebar
        if self.mobileSidebar:
          tDiv(class = "absolute right-0 top-0 flex flex-column gap-2 justify-center items-end py-12 px-4 bg-[{backHeader}]"):
            tButton(class = "pb-12"):
              "x"
              @click:
                self.mobileSidebar = not self.mobileSidebar
            component HeaderButton(text = "Blog", path = "/blog")
            component HeaderButton(text = "Features", path = "/features")
            component HeaderButton(text = "Download", path = "/download")
            component HeaderButton(text = "Documentation", path = "/docs")
            component HeaderButton(text = "Forum", path = "/forum")
            component HeaderButton(text = "Donate", path = "/donate")
            component HeaderButton(text = "Source", path = "/source")
    tDiv(class = "h-12 w-full")
