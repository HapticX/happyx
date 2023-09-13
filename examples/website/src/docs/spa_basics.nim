# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


component SpaBasics:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate"Single-page Applications Basics 🎴"}
      tP: {translate"With HappyX you can easily create modern single-page applications."}

      tH2: {translate"Features 📦"}
      tP: {translate"Here is core single-page application features 👋"}

      tUl:
        tLi: tDiv(class = "inline"):
          tSpan(class = "font-bold text-pink-800 dark:text-pink-400"): {translate"Components"}
          " "
          tSpan: {translate"Components allow you to write HTML with some OOP features and use it anywhere"}
        tLi: tDiv(class = "inline"):
          tSpan(class = "font-bold text-pink-800 dark:text-pink-400"): {translate"Event handlers"}
          " "
          tSpan: {translate"Event handlers allow you to handle button clicks, input text, and more."}
      