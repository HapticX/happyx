import
  happyx,
  ../app_config,
  header_button


component Header:
  `template`:
    tDiv(class = "fixed flex w-full items-center h-12 justify-between bg-[{backHeader}]"):
      tDiv(class = "flex items-center h-full px-2 cursor-pointer hover:bg-white/10 active:bg-white/20 transition-colors duration-500"):
        img(src = "public/logo.svg", class="h-6")
        @click:
          route("/")
      tDiv(class = "flex h-full"):
        component HeaderButton(text = "Blog", path = "/blog")
        component HeaderButton(text = "Features", path = "/features")
        component HeaderButton(text = "Download", path = "/download")
        component HeaderButton(text = "Documentation", path = "/docs")
        component HeaderButton(text = "Forum", path = "/forum")
        component HeaderButton(text = "Donate", path = "/donate")
        component HeaderButton(text = "Source", path = "/source")
    tDiv(class = "h-12 w-full")
