import
  happyx,
  ../ui/colors


component Divider:
  horizontal: bool = true
  `template`:
    if self.horizontal:
      tDiv(class = "w-full h-[2px] rounded-full bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}]")
    else:
      tDiv(class = "w-[2px] h-full rounded-full bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}]")
