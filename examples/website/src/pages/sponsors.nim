import
  ../../../../src/happyx,
  ../ui/colors,
  ../components/[header, drawer, sponsors_arr]


type
  SponsorStatus* = enum
    ssDefault,
    ssSilver,
    ssGold,
    ssPlatinum
  Sponsor* = object
    name*: string
    amount*: float
    perMonth*: bool
    url*: string
    avatarUrl*: string
    status*: SponsorStatus


var sponsor_list*: seq[Sponsor] = @[
  Sponsor(
    name: "HapticX", amount: 100.0, url: "https://github.com/HapticX",
    avatarUrl: "https://avatars.githubusercontent.com/u/124334403?s=200&v=4", status: ssSilver
  ),
  Sponsor(
    name: "Popso AI", amount: 250.0, url: "https://popso.ru/", perMonth: true,
    avatarUrl: "https://avatars.githubusercontent.com/u/7116961?v=4", status: ssGold
  ),
  Sponsor(
    name: "GoodModsLab", amount: 50.0, url: "https://goodmodslab.ru/",
    avatarUrl: "https://i.postimg.cc/8kFP5bk1/ic-logo-app-foreground.png", status: ssSilver
  )
]


proc hasLevel*(sponsor_list: seq[Sponsor], lvl: SponsorStatus): bool =
  for i in sponsor_list:
    if i.status == lvl:
      return true
  false


mount Sponsors:
  "/":
    tDiv(class = "flex flex-col min-h-screen w-full bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      # Drawer
      drawer_comp
      # Header
      tDiv(class = "w-full sticky top-0 z-20"):
        Header(drawer = drawer_comp)
      tDiv(class = "flex flex-col gap-8 items-center w-full h-full px-8"):
        tP(class = "text-7xl lg:text-5xl xl:text-3xl font-bold"):
          {translate"🔥 Sponsors"}
        if hasLevel(sponsor_list, ssPlatinum):
          Divider
          # Platinum
          tDiv(class = "flex flex-col items-center justify-center"):
            tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
              "🥇 platinum"
            SponsorsList(sponsor_list, ssPlatinum, PlatinumSponsor)
        if hasLevel(sponsor_list, ssGold):
          Divider
          # Gold
          tDiv(class = "flex flex-col items-center justify-center"):
            tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
              "🥈 gold"
            SponsorsList(sponsor_list, ssGold, GoldSponsor)
        if hasLevel(sponsor_list, ssSilver):
          Divider
          # Silver
          tDiv(class = "flex flex-col items-center justify-center"):
            tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
              "🥉 silver"
            SponsorsList(sponsor_list, ssSilver, SilverSponsor)
        if hasLevel(sponsor_list, ssDefault):
          Divider
          # Other
          tDiv(class = "flex flex-col items-center justify-center"):
            tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
              "🍕 other"
            SponsorsList(sponsor_list, ssDefault, DefaultSponsor)
        tDiv(class = "h-12")
