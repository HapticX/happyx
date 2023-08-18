# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ../ui/code,
  ../ui/play_states,
  ../components/[
    code_block_guide, code_block
  ]


component HappyxApp:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: "HappyX Application 🍍"
      tH2: "Create Application 📦"

      tDiv(class = "grid grid-cols-1 lg:grid-cols-2"):
        tDiv(class = "flex flex-col gap-4"):
          tP:
            "To create a new HappyX app you should use "
            tCode: "CLI"
            " or follow this project structure."
          tP:
            "When you use CLI, HappyX do everything for you."

        component CodeBlockGuide(@[
          ("Nim", "plaintext", nimProjectSsr, cstring"nim_proj_ssr", newPlayResult()),
          ("Nim (SPA)", "plaintext", nimProjectSpa, cstring"nim_proj_ssr", newPlayResult()),
          ("Python", "plaintext", pythonProject, cstring"py_proj", newPlayResult()),
        ])
