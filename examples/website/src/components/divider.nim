import
  ../../../../src/happyx,
  ../ui/colors


proc Divider*(horizontal: bool = true): TagRef =
  buildHtml:
    if horizontal:
      tDiv(class = "w-full h-[2px] rounded-full bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}]")
    else:
      tDiv(class = "w-[2px] h-full rounded-full bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}]")
