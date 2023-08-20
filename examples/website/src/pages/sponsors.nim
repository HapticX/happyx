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
    url*: string
    avatarUrl*: string
    status*: SponsorStatus


var sponsor_list*: seq[Sponsor] = @[
  Sponsor(
    name: "Example sponsor", amount: 100.0, url: "https://thispersondoesnotexist.com/",
    avatarUrl: "https://thispersondoesnotexist.com/", status: ssSilver
  ),
  Sponsor(
    name: "Example sponsor", amount: 100.0, url: "https://montreally.com/wp-content/uploads/cache/images/man-2/man-2-3683696497.jpg",
    avatarUrl: "https://montreally.com/wp-content/uploads/cache/images/man-2/man-2-3683696497.jpg", status: ssGold
  ),
  Sponsor(
    name: "Example sponsor", amount: 100.0, url: "https://beatmaker.tv/Default/General/Image/136200?type=BeatImageOriginal&ver=1",
    avatarUrl: "https://beatmaker.tv/Default/General/Image/136200?type=BeatImageOriginal&ver=1", status: ssGold
  ),
  Sponsor(
    name: "Example sponsor", amount: 100.0, url: "https://dspncdn.com/a1/avatars/400x/4b/75/4b756433f80f0f1a4e0b335a56a74e79.jpg",
    avatarUrl: "https://dspncdn.com/a1/avatars/400x/4b/75/4b756433f80f0f1a4e0b335a56a74e79.jpg", status: ssPlatinum
  ),
  Sponsor(
    name: "Example sponsor", amount: 100.0, url: "https://i.ytimg.com/vi/YONXRJ3OOFw/maxresdefault.jpg",
    avatarUrl: "https://i.ytimg.com/vi/YONXRJ3OOFw/maxresdefault.jpg", status: ssDefault
  ),
  Sponsor(
    name: "Example sponsor", amount: 100.0, url: "https://i.imgflip.com/1ndfj0.jpg",
    avatarUrl: "https://i.imgflip.com/1ndfj0.jpg", status: ssSilver
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
          {translate("🔥 Sponsors")}
        component Divider
        # Platinum
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            tImg(src = "/happyx/public/medal_1.svg", class = "w-16 h-16 lg:w-12 lg:h-12 xl:w-8 xl:h-8")
            "platinum"
          component SponsorsList(sponsor_list, ssPlatinum, PlatinumSponsor)
        component Divider
        # Gold
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            tImg(src = "/happyx/public/medal_2.svg", class = "w-16 h-16 lg:w-12 lg:h-12 xl:w-8 xl:h-8")
            "gold"
          component SponsorsList(sponsor_list, ssGold, GoldSponsor)
        component Divider
        # Silver
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            tImg(src = "/happyx/public/medal_3.svg", class = "w-16 h-16 lg:w-12 lg:h-12 xl:w-8 xl:h-8")
            "silver"
          component SponsorsList(sponsor_list, ssSilver, SilverSponsor)
        component Divider
        # Other
        tDiv(class = "flex flex-col items-center justify-center"):
          tP(class = "flex items-center justify-center gap-4 text-5xl lg:text-3xl xl:text-xl font-semibold"):
            "other"
          component SponsorsList(sponsor_list, ssDefault, DefaultSponsor)
        tDiv(class = "h-12")
