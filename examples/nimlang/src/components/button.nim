import
  ../../../../src/happyx,
  ../app_config


component Button:
  action: (proc(): void) = (proc() = discard)
  isPrimary: bool = true

  `template`:
    tButton(
      class =
        if self.isPrimary:
          fmt"rounded-sm px-6 py-3 bg-[{yellow}] text-[{background}] hover:bg-[{yellow}]/90 active:bg-[{yellow}]/80 transition-all dutation-500"
        else:
          fmt"rounded-sm px-6 py-3 bg-[{gray}] text-[{background}] hover:bg-[{gray}]/90 active:bg-[{gray}]/80 transition-all dutation-500"
    ):
      slot
      @click:
        self.action()
