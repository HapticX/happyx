# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, code, play_states, translations],
  ../components/[
    code_block_guide, code_block, code_block_slider, tip
  ]


proc LiveViews*(): TagRef =
  buildHtml:
    tDiv(class = "flex flex-col px-8 py-2 xl:h-fit gap-4"):
      tH1: "LiveViews 🔥"

      tP:
        {translate"Besides single-page and server-side applications, you can also develop so-called liveviews."}
      
      tP:
        {translate"Liveviews allow you to develop hybrid web applications where data processing and storage occur on the server side, while rendering happens on the client side."}

      tP:
        {translate"Below is a diagram showing the behavior of a typical hybrid application written in HappyX."}      
      tImg(src = "/happyx/public/HappyXLiveViews.svg", alt = "components lifecycle", class = "self-center rounded-xl")

      Tip(ttWarning):
        tP:
          {translate "Please note that liveviews are provided to developers as an experiment."}
          " "
          {translate"In the future, the development of liveviews is likely to be modified."}
      
      tH2: {translate"Counter App"}
      tP: {translate"Let's look at an example of a hybrid application using a counter as an example."}

      CodeBlock("nim", nimLiveViews1, "nim_liveviews_2")
