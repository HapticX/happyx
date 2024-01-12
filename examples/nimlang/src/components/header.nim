import
  ../../../../src/happyx,
  ../app_config,
  header_button


component Header:
  mobileSidebar: bool = false

  `template`:
    # Main header
    tDiv(class = "fixed z-10 flex w-full items-center px-4 h-14 justify-center bg-[{backHeader}] transition-all"):
      tDiv(class = "flex w-full h-full lg:w-3/5 justify-between"):
        # Logo container
        tDiv(class = "flex items-center h-full min-w-fit px-2 cursor-pointer hover:bg-white/10 active:bg-white/20 transition-colors duration-500"):
          img(src = "public/logo.svg", class="min-w-16 h-7")
          @click:
            route("/")
        # Header desktop buttons
        tDiv(class = "hidden lg:flex h-full"):
          tDiv(class = "flex h-full"):
            HeaderButton("/blog"): "Blog"
            HeaderButton("/features"): "Features"
            HeaderButton("/download"): "Download"
            HeaderButton("/docs"): "Documentation"
            HeaderButton("/forum"): "Forum"
            HeaderButton("/donate"): "Donate"
            HeaderButton("/source"): "Source"
        # Header mobile buttons
        tDiv(class = "flex lg:hidden text-white h-full"):
          tButton:
            "☰"
            @click:
              self.mobileSidebar = not self.mobileSidebar
          if self.mobileSidebar:
            tDiv(class = "absolute right-0 top-0 flex flex-col gap-2 justify-center items-end py-4 px-8 bg-[{backHeader}]"):
              tButton(class = "pb-12"):
                "x"
                @click:
                  self.mobileSidebar = not self.mobileSidebar
            HeaderButton("/blog"): "Blog"
            HeaderButton("/features"): "Features"
            HeaderButton("/download"): "Download"
            HeaderButton("/docs"): "Documentation"
            HeaderButton("/forum"): "Forum"
            HeaderButton("/donate"): "Donate"
            HeaderButton("/source"): "Source"
    tDiv(class = "h-12 w-full")
