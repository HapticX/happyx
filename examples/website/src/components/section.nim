import
  happyx,
  ../ui/colors


component Section:
  `template`:
    tDiv(class = "flex flex-col items-center bg-[{BackgroundSecondary}] dark:bg-[{BackgroundSecondaryDark}] w-full px-36 xl:px-96 py-24 text-3xl md:text-2xl lg:text-xl xl:text-base"):
      slot