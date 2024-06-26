import
  ../../../../src/happyx,
  ../ui/[translations]


type
  TipType* {.size: sizeof(int8), pure.} = enum
    ttTip,
    ttWarning,
    ttInfo


proc Tip*(mode: TipType = TipType.ttTip, stmt: TagRef = nil): TagRef =
  buildHtml:
    tDiv(
      class =
        case mode
        of ttTip:
          "flex flex-col w-fit gap-2 border-l-4 rounded-r-md border-green-700 bg-green-200/25 dark:border-green-300 px-4 py-2"
        of ttWarning:
          "flex flex-col w-fit gap-2 border-l-4 rounded-r-md border-yellow-700 bg-yellow-200/25 dark:border-yellow-300 px-4 py-2"
        of ttInfo:
          "flex flex-col w-fit gap-2 border-l-4 rounded-r-md border-orange-700 bg-orange-200/25 dark:border-orange-300 px-4 py-2"
    ):
      tB:
        case mode
        of ttTip:
          {translate"TIP"}
        of ttWarning:
          {translate"Warning"}
        of ttInfo:
          {translate"Info"}
      if not stmt.isNil:
        stmt
