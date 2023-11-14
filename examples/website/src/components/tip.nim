import
  ../../../../src/happyx,
  ../ui/[colors, translations]


component Tip:
  `template`:
    tDiv(
      class = "flex flex-col w-fit gap-2 border-l-4 rounded-r-md border-green-700 bg-green-200/25 dark:border-green-300 px-4 py-2"
    ):
      tB: {translate"TIP"}
      slot
