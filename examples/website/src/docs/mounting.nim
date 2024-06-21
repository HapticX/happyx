# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider, tip
  ]


proc Mounting*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"Third-party routes 💫"}

      tP:
        {translate"Server applications typically have a large number of routes."}
        " "
        {translate"For convenience, it is customary to separate them."}
        " "
        {translate"In HappyX, this is done using mounting."}
      
      tP: {translate"Let's take a look at the example below:"}

      CodeBlockGuide(@[
        ("Nim", "nim", nimSsrMounting, cstring"nim_ssr_mounting", newPlayResult()),
        ("Nim (SPA)", "nim", nimSpaMounting, cstring"nim_spa_mounting", newPlayResult()),
        ("Python", "python", pyMounting, cstring"py_mounting", newPlayResult()),
        ("JavaScript", "javascript", jsMounting, cstring"js_mounting", newPlayResult()),
        ("TypeScript", "typescript", tsMounting, cstring"ts_mounting", newPlayResult()),
      ])

      tP:
        {translate"Here we define additional routes that start with"}
        " "
        tCode:
          "/profile"
        ". "
      
      Tip(ttTip):
        tP:
          {translate"It is important to note that such mounted routes can easily be moved to separate files and modules for greater convenience."}
      
      if currentLanguage in ["Nim", "Nim (SPA)"]:
        tH2:
          {translate"A little sugar"}
        tP:
          {translate"Using Nim, you can also use syntactic sugar that allows you to define separate routes without resorting to mounting:"}

        CodeBlockGuide(@[
          ("Nim", "nim", nimSsrMountingSugar, cstring"nim_ssr_mounting_sugar", newPlayResult()),
          ("Nim (SPA)", "nim", nimSpaMountingSugar, cstring"nim_spa_mounting_sugar", newPlayResult()),
        ])

