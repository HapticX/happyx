import
  ../../../../src/happyx,
  ../app_config


component Heading:
  level: int = 1
  html:
    tDiv(class = "text-{self.getSize(9)} lg:text-{self.getSize(7)} xl:text-{self.getSize(6)}"):
      slot
  
  [methods]:
    proc getSize(size: int): string =
      case size - self.level.val
      of 9,8,7,6,5,4,3,2:
        fmt"{size - self.level.val}xl"
      of 1:
        "xl"
      of 0:
        "lg"
      of -1:
        "base"
      of -2:
        "sm"
      else:
        "xs"
