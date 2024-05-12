# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


proc TailwindAndOther*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"Tailwind And Other 🎴"}

      tP: {translate"You can actually use most of the JS libraries with HappyX"}

      tH2: {translate"Simple Usage 🔨"}

      tP: {translate"To use JS libraries you can use cdn."}

      tP: {translate"SSR Nim Version can be:"}
      CodeBlock("nim", nimSsrTailwind, "tailwind_ssr")
      tP: {translate"SPA Nim Version can be:"}
      CodeBlock("html", nimSpaHtmlTailwind, "tailwind_spa_html")
      CodeBlock("nim", nimSpaTailwind, "tailwind_spa_nim")

      tH2: {translate"Advanced Usage with NodeJS 🧪"}

      tP:
        {translate"Some libraries provides CLI and other tools to working."}
      tP:
        {translate"Going back to Tailwind CSS - it has an observing CLI. With it, you can use Tailwind without the CLI. "}
        tA(href = "https://tailwindcss.com/docs/installation"):
          "Tailwind Docs"
      
      tP: {translate"To use it let's repeat these steps:"}
      CodeBlock("shell", tailwindCli, "tailwind_init_project")
      tP:
        {translate"Then, go to "}
        tCode: "tailwind.config.js"
        {translate" and change it"}
      CodeBlock("javascript", tailwindConfig, "tailwind_config")
      tP:
        {translate"After, create "}
        tCode: "src/public/input.css"
      CodeBlock("css", tailwindCssInput, "tailwind_css_input")
      tP: {translate"And run watching command"}
      CodeBlock("shell", tailwindWatch, "tailwind_watch")

      tP:
        {translate"After all steps you can write any html/nim files with tailwind support"}
      tP:
        {translate"SSR Nim Version can be:"}
        tCode: "src/main.nim"
      CodeBlock("nim", nimSsrTailwindWithoutCdn, "tailwind_spa_nim")
      tP:
        {translate"SPA Nim Version can be:"}
        tCode: "src/main.nim"
      CodeBlock("nim", nimSpaTailwind, "tailwind_spa_nim")
