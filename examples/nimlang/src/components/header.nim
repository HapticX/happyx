import
  ../../../../src/happyx,
  ../app_config,
  header_button


proc Header*(): TagRef =
  buildHtml:
    # Main header
    tDiv(class = "fixed z-10 flex w-full items-center px-4 h-20 lg:h-14 justify-center bg-[{backHeader}] transition-all"):
      tDiv(class = "flex w-full h-full lg:w-4/5 2xl:!w-3/5 justify-between"):
        # Logo container
        tDiv(class = "flex items-center h-full min-w-fit px-2 cursor-pointer hover:bg-white/10 active:bg-white/20 transition-colors duration-500"):
          img(src = "public/logo.svg", class="min-w-24 h-12 lg:min-w-16 lg:h-7")
          @click:
            route"/"
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
        tDiv(class = "flex lg:hidden text-white text-4xl font-semibold h-full"):
          tButton:
            "☰"
            @click:
              discard
    tDiv(class = "h-12 w-full")
