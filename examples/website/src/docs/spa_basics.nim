# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


proc SpaBasics*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"Single-page Applications Basics 🎴"}
      tP: {translate"With HappyX you can easily create modern single-page applications."}
      tP: {translate"SPA means that all web-app logic runs at the client-side (e.g., browser)."}

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
        tLi: tDiv(class = "inline"):
          tSpan(class = "font-bold text-pink-800 dark:text-pink-400"): {translate"Routes"}
          " "
          tSpan: {translate"Routes allows to move between different pages"}
      
      tH2: {translate"Routing 🔌"}
      tP: {translate"Here is routing basics."}

      CodeBlock("nim", nimSpaRouting, "nim_spa_routing")

      tH2: {translate"Reactivity ⚡"}

      tP:
        {translate"Reactivity in HappyX is a mechanism that allows your web application to instantly respond to data changes without explicit developer intervention. When the data used in the application changes, the interface is automatically updated to display these changes. This makes the app more responsive and user-friendly."}
      
      tP: {translate"Here is 'naked' reactivity without components:"}
      CodeBlock("nim", nimSpaReactivity, "nim_spa_reactivity")

      tP: {translate"And here is reactivity with components usage:"}
      CodeBlock("nim", nimSpaComponentReactivity, "nim_spa_component_reactivity")

      tP: {translate"Reactivity is described in more detail in the following article."}
