import
  happyx,
  ../ui/colors,
  ../components/[button]


component Drawer:
  isOpen: bool = false

  `template`:
    # Drawer background
    nim:
      echo 2
    tDiv(id = "drawerBack", class = "fixed right-0 duration-500 transition-all w-0 h-screen z-50 drawer-back bg-[#00000040]"):
      @click:
        self.toggle()
  
  [methods]:
    proc toggle*() =
      enableRouting = false
      let
        drawerBack = elem(drawerBack)
      self.isOpen.set(not self.isOpen)
      if self.isOpen:
        drawerBack.classList.remove("w-0")
        drawerBack.classList.add("w-1/2")
      else:
        drawerBack.classList.remove("w-1/2")
        drawerBack.classList.add("w-0")
      echo "toggled!"
      enableRouting = true
