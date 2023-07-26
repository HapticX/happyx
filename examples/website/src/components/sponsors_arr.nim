import
  ../../../../src/happyx,
  ../ui/colors,
  ../pages/[sponsors]


component SponsorsList:
  data: seq[Sponsor] = @[]
  sponsorStatus: SponsorStatus = ssDefault
  colorBorder: string = DefaultSponsor

  `template`:
    tDiv(class = "w-full grid grid-cols-4 lg:grid-cols-6 xl:grid-cols-10 pt-4 gap-1"):
      for sponsor in self.data:
        if (remember sponsor.status) == self.sponsorStatus:
          tImg(
            src = sponsor.avatarUrl,
            alt = fmt"{sponsor.name}, ${sponsor.amount}",
            title = fmt"{sponsor.name}, ${sponsor.amount}",
            class = "border-[{self.colorBorder}] border-4 w-24 h-24 rounded-full"
          ):
            @click:
              {.emit: """//js
              window.open(`sponsor`.`url`, '_blank').focus();
              """.}
