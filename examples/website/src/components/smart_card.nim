import
  ../../../../src/happyx,
  ../ui/colors


proc SmartCard*(stmt: TagRef): TagRef =
  buildHtml:
    tDiv(
      class = "flex justify-center items-center gap-12 w-fit drop-shadow-2xl rounded-md bg-gradient-to-r bg-[{Background}] dark:from-[{BackgroundDark}] dark:to-[{BackgroundSecondaryDark}] text-3xl md:text-2xl lg:text-xl xl:text-base px-8 py-4"
    ):
      stmt
