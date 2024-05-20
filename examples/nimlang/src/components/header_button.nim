import
  ../../../../src/happyx,
  ../app_config


proc HeaderButton*(path: cstring = "/", stmt: TagRef): TagRef =
  buildHtml:
    tButton:
      class := (
        if currentRoute == path:
          "flex font-medium justify-center items-center text-white h-full px-4 bg-white/10 hover:bg-white/20 active:bg-white/30 transition-colors duration-500"
        else:
          "flex font-medium justify-center items-center text-white h-full px-4 hover:bg-white/10 active:bg-white/20 transition-colors duration-500"
      )
      stmt
      @click:
        route(path)
