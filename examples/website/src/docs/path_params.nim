# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block
  ]


component HappyxApp:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate("Path Params 🔌")}
