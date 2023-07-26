import
  ../../../../src/happyx,
  ../ui/colors


component Section:
  `template`:
    tDiv(class = "flex flex-col items-center bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] w-full px-12 xl:px-96 py-24 text-3xl lg:text-lg xl:text-base"):
      slot
