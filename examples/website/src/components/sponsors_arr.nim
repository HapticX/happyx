import
  ../../../../src/happyx,
  ../ui/colors,
  ../pages/[sponsors]


proc SponsorsList*(data: seq[Sponsor], sponsorStatus: SponsorStatus = ssDefault,
                   colorBorder: string = DefaultSponsor): TagRef =
  let color =
    case sponsorStatus:
      of ssPlatinum: "0px 5px 51px 0px rgba(179, 212, 238, 0.1)"
      of ssGold: "0px 5px 51px 0px rgba(250, 204, 21, 0.1)"
      of ssSilver: "0px 5px 51px 0px rgba(226, 232, 240, 0.1)"
      of ssDefault: "0px 5px 51px 0px rgba(248, 250, 252, 0.1)"
  let className =
    case sponsorStatus:
      of ssPlatinum: "sponsor-platinum"
      of ssGold: "sponsor-gold"
      of ssSilver: "sponsor-silver"
      of ssDefault: "sponsor-default"
  let hover =
    case sponsorStatus:
      of ssPlatinum: "0px 5px 51px 0px rgba(179, 212, 238, 0.5)"
      of ssGold: "0px 5px 51px 0px rgba(250, 204, 21, 0.5)"
      of ssSilver: "0px 5px 51px 0px rgba(226, 232, 240, 0.5)"
      of ssDefault: "0px 5px 51px 0px rgba(248, 250, 252, 0.5)"
  buildHtml:
    tDiv(class = "w-full grid grid-cols-4 lg:grid-cols-6 xl:grid-cols-10 pt-4 gap-4"):
      for sponsor in data:
        if sponsor.status == sponsorStatus:
          tDiv(
            class = "bg-black rounded-full {className} transition-all duration-300"
          ):
            tA(
              class = "group relative",
              href = sponsor.url,
              target = "_blank"
            ):
              tImg(
                src = sponsor.avatarUrl,
                alt = fmt"{sponsor.name}, ${sponsor.amount}",
                class = "border-[{colorBorder}] border-4 w-24 h-24 rounded-full"
              )
              tDiv(
                class = "flex mt-0 group-hover:mt-6 rounded-md text-center text-[{Foreground}] dark:text-[{ForegroundDark}] bg-[{Background}] dark:bg-[{BackgroundDark}] justify-content items-center pointer-events-none absolute delay-150 opacity-0 transition-all duration-300 group-hover:opacity-100"
              ):
                if sponsor.perMonth:
                  {fmt"{sponsor.name} ${sponsor.amount}/month"}
                else:
                  {fmt"{sponsor.name} ${sponsor.amount}"}
            tStyle: {fmt("""
              div.<className> {
                -webkit-box-shadow: <color>;
                -moz-box-shadow: <color>;
                box-shadow: <color>;
              }
              div.<className>:hover {
                -webkit-box-shadow: <hover>;
                -moz-box-shadow: <hover>;
                box-shadow: <hover>;
              }
            """, '<', '>')}
