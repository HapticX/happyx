# Import HappyX
import
  ../../../../../src/happyx,
  ../../ui/[colors, code, play_states, translations],
  ../../components/[
    code_block_guide, code_block
  ]


component DbIntro:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tH1: {translate("Database access 📦")}

      tP: {translate"In the following articles, we will look at the interaction with databases on the server side."}

      tP: {translate"You can use any available database driver implemented in Nim, Python or NodeJS"}
