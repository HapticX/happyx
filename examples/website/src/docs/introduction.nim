# Import HappyX
import
  ../../../../src/happyx,
  ../ui/[colors, translations],
  ../components/[code_block_guide, tip]


component IntroductionLanguageChooser:
  lang: string
  title: string
  `template`:
    tDiv(
      class =
        if self.lang == currentLanguage:
          "bg-yellow-400/20 dark:bg-yellow-300/25 px-4 py-2 select-none cursor-pointer rounded-md transition-all"
        else:
          "bg-yellow-400/20 hover:bg-yellow-400/30 active:bg-yellow-400/40 dark:bg-yellow-200/10 px-4 py-2 select-none cursor-pointer rounded-md transition-all dark:hover:bg-yellow-200/20 dark:active:bg-yellow-300/10"
    ):
      {self.title}
      @click:
        var lang: cstring = $(self.IntroductionLanguageChooser.lang.val)
        buildJs:
          console.log(~lang)
          localStorage["happyx_programming_language"] = ~lang
        currentLanguage.set(self.lang)
        application.router()


component Contributor:
  nickname: string
  url: string
  avatar: string

  `template`:
    tA(class = "flex flex-col justify-center items-center", href = "{self.url}"):
      tImg(src = "{self.avatar}", class = "w-[96px] lg:w-[72px] xl:w-[64px] h-[96px] lg:h-[72px] xl:h-[64px] rounded-full", alt = "{self.nickname}")
      tP(class = "font-mono text-center h-8"):
        {self.nickname}


component Introduction:
  `template`:
    tDiv(class = "flex flex-col px-8 py-2 backdrop-blur-sm xl:h-fit gap-4"):
      tImg(src = "/happyx/public/icon.png", class = "self-center w-72 h-72")
      tH1: {translate("Introduction ✌")}
      tTable:
        tTbody:
          tTr:
            tTd: "GitHub"
            tTd:
              tA(href = "https://github.com/HapticX/happyx"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Github Issues", src = "https://img.shields.io/github/issues/HapticX/happyx?style=for-the-badge")
              tA(href = "https://github.com/HapticX/happyx"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Github Closed Issues", src = "https://img.shields.io/github/issues-closed/HapticX/happyx?style=for-the-badge")
              tA(href = "https://github.com/HapticX/happyx"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Github Stars", src = "https://img.shields.io/github/stars/HapticX/happyx?style=for-the-badge")
          tTr:
            tTd: "Tests"
            tTd:
              tA(href = "https://github.com/HapticX/happyx/actions/workflows/tests.yml"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Github Issues", src = "https://img.shields.io/github/actions/workflow/status/HapticX/HappyX/tests.yml?label=Testing&logo=github&style=for-the-badge")
          tTr:
            tTd: "Languages"
            tTd:
              tA(href = "https://nim-lang.org"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Nim 👑", src = "https://img.shields.io/badge/>=1.6.14-1b1e2b?style=for-the-badge&logo=nim&logoColor=f1fa8c&label=Nim&labelColor=2b2e3b")
              tA(href = "https://python.org"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Python 🐍", src = "https://img.shields.io/badge/>=3.7.x-1b1e2b?style=for-the-badge&logo=python&logoColor=f1fa8c&label=Python&labelColor=2b2e3b")
              tA(href = "https://developer.mozilla.org/en-US/docs/Web/JavaScript"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "JavaScript ✌", src = "https://img.shields.io/badge/ES6-1b1e2b?style=for-the-badge&logo=javascript&logoColor=f1fa8c&label=JavaScript&labelColor=2b2e3b")
              tA(href = "https://www.typescriptlang.org/"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "TypeScript 🔥", src = "https://img.shields.io/badge/>=5.2.2-1b1e2b?style=for-the-badge&logo=typescript&logoColor=f1fa8c&label=TypeScript&labelColor=2b2e3b")
          tTr:
            tTd: "Wakatime Stats"
            tTd:
              tA(href = "https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Wakatime", src = "https://wakatime.com/badge/user/eaf11f95-5e2a-4b60-ae6a-38cd01ed317b/project/bbd13748-36e6-4383-ac40-9c4e72c060d1.svg?style=for-the-badge")
          tTr:
            tTd: "VS Code Plugin"
            tTd:
              tA(href = "https://github.com/HapticX/hpx-vs-code"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "VS Code Plugin Repository", src = "https://img.shields.io/badge/Plugin-1b1e2b?style=for-the-badge&logo=visualstudiocode&logoColor=f1fa8c&label=VS%20Code&labelColor=2b2e3b")
              tA(href = "https://marketplace.visualstudio.com/items?itemName=HapticX.happyx"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Visual Studio Marketplace Installs - Azure DevOps Extension", src = "https://img.shields.io/visual-studio-marketplace/azure-devops/installs/total/HapticX.happyx?style=for-the-badge")
          tTr:
            tTd: "PyPI"
            tTd:
              tA(href = "https://pypi.org/project/happyx/"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "PyPI Downloads", src = "https://img.shields.io/pypi/dm/happyx?style=for-the-badge")
          tTr:
            tTd: "npm"
            tTd:
              tA(href = "https://www.npmjs.com/package/happyx"):
                tImg(class = "h-12 lg:h-10 xl:h-8", alt = "Npm Downloads", src = "https://img.shields.io/npm/dm/happyx?style=for-the-badge")
      tH2: {translate("What Is HappyX? 💡")}
      tP:
        tB: "HappyX"
        {translate("""
        is a macro-oriented full-stack web framework, written in Nim.
        This project has been under development since April 2023 and is continuously evolving.
        HappyX draws inspiration from notable web frameworks like Vue.js and FastAPI.
        """)}
      component Tip:
        tP:
          {translate("HappyX works with Nim, Python, JavaScript and TypeScript so you can choose one of these languages to read this guide ✌")}
        tDiv(
          class = "flex justify-around items-center w-full"
        ):
          component IntroductionLanguageChooser("Nim", "Nim 👑")
          component IntroductionLanguageChooser("Python", "Python 🐍")
          component IntroductionLanguageChooser("JavaScript", "JavaScript ✌")
          component IntroductionLanguageChooser("TypeScript", "TypeScript 🔥")
      tP:
        tB: {translate("If you:")}
        tUl:
          tLi: {translate("are not keen on constantly \"switching\" your mindset from one language or web framework to another 🔥")}
          tLi: {translate("desire a lightweight web framework ⚡")}
          tLi: {translate("seek a web framework with everything \"out of the box\" 📦")}
        tB: {translate("Then, HappyX is the perfect fit for you. 😉")}
      tH2: {translate("Features 🔥")}
      tUl:
        tLi: {translate("Production-ready 🔌")}
        tLi: {translate("Multiple server options 🌩")}
        tLi: {translate("Support Single-page applications, Static site generation and Server-side rendering 💫")}
        tLi: {translate("Own Domain-specific languages for HTML, CSS and JavaScript 🎴")}
        tLi: {translate("Hot code reloading (only for Single-page applications for now) ⚡")}
        tLi: {translate("Routing/mounting with path param validation 👮‍♀️")}
        tLi: {translate("CLI for creating, serving and building your projects 💻")}
        tLi: {translate("Request models that supports JSON, FormData, x-www-form-urlencoded and XML 👮‍♀️")}
        tLi: {translate("Translating, logging, security, built-in UI and more other features \"out of the box\" 📦")}
      
      tDiv(class = "flex flex-col gap-8 pt-4"):
        tH2: {translate("Community 🌎")}
        tDiv(class = "flex flex-col gap-4"):
          tH3: {translate("Maintainers")}
          tDiv(class = "grid grid-cols-5 lg:grid-cols-10 xl:grid-cols-15 gap-x-2 gap-y-8"):
            component Contributor("Ethosa", "https://github.com/Ethosa", "https://avatars.githubusercontent.com/u/49402667?v=4")
        tDiv(class = "flex flex-col gap-4"):
          tH3: {translate("Contributors")}
          tDiv(class = "grid grid-cols-5 lg:grid-cols-10 xl:grid-cols-15 gap-x-2 gap-y-12"):
            component Contributor("quimt", "https://github.com/quimt", "https://avatars.githubusercontent.com/u/126020181?v=4")
            component Contributor("its5Q", "https://github.com/its5Q", "https://avatars.githubusercontent.com/u/12975646?v=4")
            component Contributor("Lum", "https://github.com/not-lum", "https://avatars.githubusercontent.com/u/62594565?v=4")
            component Contributor("Array in a Matrix", "https://github.com/array-in-a-matrix", "https://avatars.githubusercontent.com/u/78233840?v=4")
            component Contributor("MCRusher", "https://github.com/MCRusher", "https://avatars.githubusercontent.com/u/16050377?v=4")
            component Contributor("Sultan Al Isaiee", "https://github.com/foxoman", "https://avatars.githubusercontent.com/u/5356677?v=4")
            component Contributor("Arik Rahman", "https://github.com/ArikRahman", "https://avatars.githubusercontent.com/u/40479733?v=4")
            component Contributor("horanchikk", "https://github.com/horanchikk", "https://avatars.githubusercontent.com/u/46918417?v=4")
            component Contributor("Stephan Zhdanov", "https://github.com/ret7020", "https://avatars.githubusercontent.com/u/55328925?v=4")
            component Contributor("lost22git", "https://github.com/lost22git", "https://avatars.githubusercontent.com/u/65008815?v=4")
            component Contributor("Optimax125", "https://github.com/Optimax125", "https://avatars.githubusercontent.com/u/53735809?v=4")
            component Contributor("jbjuin", "https://github.com/jbjuin", "https://avatars.githubusercontent.com/u/2361571?v=4")
            component Contributor("Matthew Stopa", "https://github.com/MattStopa", "https://avatars.githubusercontent.com/u/191057?v=4")
            component Contributor("Carlo Capocasa", "https://github.com/capocasa", "https://avatars.githubusercontent.com/u/1167940?v=4")
            component Contributor("Alikusnadi", "https://github.com/dodolboks", "https://avatars.githubusercontent.com/u/91905?v=4")
            component Contributor("XADE", "https://github.com/imxade", "https://avatars.githubusercontent.com/u/56511165?v=4")
            component Contributor("Thiago", "https://github.com/thisago", "https://avatars.githubusercontent.com/u/74574275?v=4")
            component Contributor("svenrdz", "https://github.com/svenrdz", "https://avatars.githubusercontent.com/u/23420779?v=4")
            component Contributor("monocoder", "https://github.com/monocoder", "https://avatars.githubusercontent.com/u/7921660?v=4")
            component Contributor("JK", "https://github.com/jerrygzy", "https://avatars.githubusercontent.com/u/181757?v=4")
            component Contributor("sjhaleprogrammer", "https://github.com/sjhaleprogrammer", "https://avatars.githubusercontent.com/u/60676867?v=4")
            component Contributor("Constantine Molchanov", "https://github.com/moigagoo", "https://avatars.githubusercontent.com/u/1045340?v=4")
