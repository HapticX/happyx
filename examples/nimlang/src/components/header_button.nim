import
  ../../../../src/happyx,
  ../app_config


component HeaderButton:
  path: cstring = "/"

  `template`:
    tButton:
      class := (
        if currentRoute == self.path:
          "flex font-medium justify-center items-center text-white h-full px-4 bg-white/10 hover:bg-white/20 active:bg-white/30 transition-colors duration-500"
        else:
          "flex font-medium justify-center items-center text-white h-full px-4 hover:bg-white/10 active:bg-white/20 transition-colors duration-500"
      )
      slot
      @click:
        route(self.path)
