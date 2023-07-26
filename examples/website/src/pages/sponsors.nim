import
  happyx,
  ../ui/colors,
  ../components/[header, drawer]


type
  SponsorStatus* = enum
    ssDefault,
    ssSilver,
    ssGold,
    ssPlatinum
  Sponsor* = object
    name*: string
    amount*: float
    url*: string
    avatarUrl*: string
    status*: SponsorStatus


var sponsor_list* = @[
  Sponsor(
    name: "Ethosa", amount: 1.0, url: "https://github.com/Ethosa",
    avatarUrl: "https://avatars.githubusercontent.com/u/49402667?v=4"
  ),
  Sponsor(
    name: "Dmitry Kotov", amount: 255.0, url: "https://github.com/dmitrijkotov634",
    avatarUrl: "https://avatars.githubusercontent.com/u/53375304?v=4", status: ssGold
  ),
  Sponsor(
    name: "Pisya Popa", amount: 1000.0, url: "https://vk.com/bbfulbe2",
    avatarUrl: "https://sun9-20.userapi.com/impg/hp4zSGSSU5qhjVI4FS9T3Fto5EeIotQr2ZkVnQ/5_6yfsCPTCk.jpg?size=807x1080&quality=96&sign=f5db819ee722921d326f7973857c9f7d&type=album", status: ssPlatinum,
  ),
  Sponsor(
    name: "Vadim Morozov", amount: 100.0, url: "https://github.com/horanchikk",
    avatarUrl: "https://avatars.githubusercontent.com/u/46918417?v=4", status: ssSilver
  ),
]


mount Sponsors:
  "/":
    tDiv(class = "flex flex-col min-h-screen w-full bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      # Drawer
      component drawer_comp
      # Header
      tDiv(class = "w-full sticky top-0 z-20"):
        component Header(drawer = drawer_comp)
      tDiv(class = "flex flex-col gap-8 items-center w-full h-full px-8"):
        tP(class = "text-7xl lg:text-5xl xl:text-3xl font-bold"):
          "sponsors"
        component Divider
        # Platinum
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            tImg(src = "/happyx/public/medal_1.svg", class = "w-16 h-16 lg:w-12 lg:h-12 xl:w-8 xl:h-8")
            "platinum"
          tDiv(class = "w-full grid grid-cols-4 lg:grid-cols-6 xl:grid-cols-10 pt-4 gap-1"):
            for sponsor in sponsor_list:
              if sponsor.status == ssPlatinum:
                tImg(src = sponsor.avatarUrl, alt = fmt"{sponsor.name}, ${sponsor.amount}", title = fmt"{sponsor.name}, ${sponsor.amount}", class = "border-[{PlatinumSponsor}] border-2 w-24 h-24 rounded-full"):
                  @click:
                    {.emit: """//js
                    window.open(`sponsor`.`url`, '_blank').focus();
                    """.}
        component Divider
        # Gold
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            tImg(src = "/happyx/public/medal_2.svg", class = "w-16 h-16 lg:w-12 lg:h-12 xl:w-8 xl:h-8")
            "gold"
          tDiv(class = "w-full grid grid-cols-4 lg:grid-cols-6 xl:grid-cols-10 pt-4 gap-1"):
            for sponsor in sponsor_list:
              if sponsor.status == ssGold:
                tImg(src = sponsor.avatarUrl, alt = fmt"{sponsor.name}, ${sponsor.amount}", title = fmt"{sponsor.name}, ${sponsor.amount}", class = "border-[{GoldSponsor}] border-2 w-24 h-24 rounded-full"):
                  @click:
                    {.emit: """//js
                    window.open(`sponsor`.`url`, '_blank').focus();
                    """.}
        component Divider
        # Silver
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            tImg(src = "/happyx/public/medal_3.svg", class = "w-16 h-16 lg:w-12 lg:h-12 xl:w-8 xl:h-8")
            "silver"
          tDiv(class = "w-full grid grid-cols-4 lg:grid-cols-6 xl:grid-cols-10 pt-4 gap-1"):
            for sponsor in sponsor_list:
              if sponsor.status == ssSilver:
                tImg(src = sponsor.avatarUrl, alt = fmt"{sponsor.name}, ${sponsor.amount}", title = fmt"{sponsor.name}, ${sponsor.amount}", class = "border-[{SilverSponsor}] border-2 w-24 h-24 rounded-full"):
                  @click:
                    {.emit: """//js
                    window.open(`sponsor`.`url`, '_blank').focus();
                    """.}
        component Divider
        # Other
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            "other"
          tDiv(class = "w-full grid grid-cols-4 lg:grid-cols-6 xl:grid-cols-10 pt-4 gap-1"):
            for sponsor in sponsor_list:
              if sponsor.status == ssDefault:
                tImg(src = sponsor.avatarUrl, alt = fmt"{sponsor.name}, ${sponsor.amount}", title = fmt"{sponsor.name}, ${sponsor.amount}", class = "border-[{DefaultSponsor}] border-2 w-24 h-24 rounded-full"):
                  @click:
                    {.emit: """//js
                    window.open(`sponsor`.`url`, '_blank').focus();
                    """.}
        tDiv(class = "h-12")
