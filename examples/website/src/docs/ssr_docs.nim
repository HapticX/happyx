# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider
  ]


proc SsrDocs*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: {translate"Swagger and Redoc in HappyX 📕"}

      tP: {translate"In this section, we will talk about using Swagger and Redoc in HappyX."}

      tP: {translate"Let's start by creating a basic route that will return Hello, world! We'll document it right away."}

      CodeBlock("nim", nimSsrDocs1, "nim_ssr_docs_1")

      tP:
        {translate"Now that we've documented it, let's go ahead and run it and check the following address:"}
        " "
        tA(href = "http://localhost:5000/docs/redoc"):
          "http://localhost:5000/docs/redoc"

      tP:
        {translate"Here we can see our route and the description we provided for it. You can also view the Swagger documentation at the following address:"}
        " "
        tA(href = "http://localhost:5000/docs/swagger"):
          "http://localhost:5000/docs/swagger"
      
      tP: {translate"In addition, for Swagger, you can write in Markdown:"}
      
      CodeBlock("nim", nimSsrDocs2, "nim_ssr_docs_2")
