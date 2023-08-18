# Import HappyX
import
  ../../../../src/happyx,
  ../ui/colors,
  ../components/[code_block_guide]


component IntroductionLanguageChooser:
  lang: string
  title: string
  `template`:
    tDiv(
      class =
        if self.lang == currentLanguage:
          "bg-yellow-300/25 px-4 py-2 select-none cursor-pointer rounded-md"
        else:
          "bg-yellow-200/10 px-4 py-2 select-none cursor-pointer rounded-md"
    ):
      {self.title}
      @click:
        var lang: cstring = $(self.IntroductionLanguageChooser.lang.val)
        buildJs:
          localStorage["happyx_programming_language"] = ~lang
        currentLanguage.set(self.lang)


component Introduction:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tImg(src = "/happyx/public/logo.svg", class = "self-center")
      tH1: "Introduction ✌"
      tTable:
        tTbody:
          tTr:
            tTd: "GitHub"
            tTd:
              tA(href = "https://github.com/HapticX/happyx"):
                tImg(alt = "Github Issues", src = "https://img.shields.io/github/issues/HapticX/happyx?style=for-the-badge")
              tA(href = "https://github.com/HapticX/happyx"):
                tImg(alt = "Github Closed Issues", src = "https://img.shields.io/github/issues-closed/HapticX/happyx?style=for-the-badge")
              tA(href = "https://github.com/HapticX/happyx"):
                tImg(alt = "Github Stars", src = "https://img.shields.io/github/stars/HapticX/happyx?style=for-the-badge")
          tTr:
            tTd: "Tests"
            tTd:
              tA(href = "https://github.com/HapticX/happyx/actions/workflows/tests.yml"):
                tImg(alt = "Github Issues", src = "https://img.shields.io/github/actions/workflow/status/HapticX/HappyX/tests.yml?label=Testing&logo=github&style=for-the-badge")
          tTr:
            tTd: "Languages"
            tTd:
              tA(href = "https://nim-lang.org"):
                tImg(alt = "Nim 👑", src = "https://img.shields.io/badge/>=1.6.14-1b1e2b?style=for-the-badge&logo=nim&logoColor=f1fa8c&label=Nim&labelColor=2b2e3b")
              tA(href = "https://python.org"):
                tImg(alt = "Python 🐍", src = "https://img.shields.io/badge/>=3.10.x-1b1e2b?style=for-the-badge&logo=python&logoColor=f1fa8c&label=Python&labelColor=2b2e3b")
          tTr:
            tTd: "Wakatime Stats"
            tTd:
              tA(href = "https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1"):
                tImg(alt = "Wakatime", src = "https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1.svg?style=for-the-badge")
          tTr:
            tTd: "VS Code Plugin"
            tTd:
              tA(href = "https://github.com/HapticX/hpx-vs-code"):
                tImg(alt = "VS Code Plugin Repository", src = "https://img.shields.io/badge/Plugin-1b1e2b?style=for-the-badge&logo=visualstudiocode&logoColor=f1fa8c&label=VS%20Code&labelColor=2b2e3b")
              tA(href = "https://marketplace.visualstudio.com/items?itemName=HapticX.happyx"):
                tImg(alt = "Visual Studio Marketplace Installs - Azure DevOps Extension", src = "https://img.shields.io/visual-studio-marketplace/azure-devops/installs/total/HapticX.happyx?style=for-the-badge")
          tTr:
            tTd: "PyPI"
            tTd:
              tA(href = "https://pypi.org/project/happyx/"):
                tImg(alt = "PyPI Downloads", src = "https://img.shields.io/pypi/dm/happyx?style=for-the-badge")
      tH2: "What Is HappyX? 💡"
      tP:
        tB: "HappyX"
        """
        is A macro-oriented full-stack web framework, lovingly crafted in Nim.
        This project has been under development since April 2023 and is continuously evolving.
        HappyX draws inspiration from notable web frameworks like Vue.js and FastAPI.  
        """
      tDiv(
        class = "flex flex-col w-fit gap-2 border-l-4 rounded-r-md border-green-700 bg-green-200/25 dark:border-green-300 px-4 py-2"
      ):
        tB: "TIP"
        tP:
          "HappyX works with Nim and Python so you can choose on of these languages to read this guide ✌"
        tDiv(
          class = "flex justify-around items-center w-full"
        ):
          component IntroductionLanguageChooser("Nim", "Nim 👑")
          component IntroductionLanguageChooser("Python", "Python 🐍")
      tP:
        tB: "If you:"
        tUl:
          tLi: "are not keen on constantly \"switching\" your mindset from one language or web framework to another 🔥"
          tLi: "desire a lightweight web framework ⚡"
          tLi: "seek a web framework with everything \"out of the box\" 📦"
        tB: "Then, HappyX is the perfect fit for you. 😉"
      tH2: "Features 🔥"
      tUl:
        tLi: "Production ready 🔌"
        tLi: "Multiple server options 🌩"
        tLi: "Support Single-page applications, Static site generation and Server-side rendering 💫"
        tLi: "Own Domain-specific languages for HTML, CSS and JavaScript 🎴"
        tLi: "Hot code reloading (only for Single-page applications for now) ⚡"
        tLi: "Routing/mounting with path param validation 👮‍♀️"
        tLi: "CLI for creating, serving and building your projects 💻"
        tLi: "Request models that supports JSON, FormData, x-www-form-urlencoded and XML 👮‍♀️"
        tLi: "Translating, logging, security, built-in UI and more other features \"out of the box\" 📦"
