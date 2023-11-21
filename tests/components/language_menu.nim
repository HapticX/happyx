import ../../src/happyx


proc menuList(lang: seq[(string, string)]): TagRef =
  return buildHtml:
    for i, l in lang: 
      tLi:
        tButton(
            class =
              if i == 0:
                "active"
              else:
                ""
        ):
          tSpan(class="badge badge-sm badge-outline !pl-1.5 !pr-1 pt-px font-mono !text-[.6rem] font-bold tracking-widest opacity-50"):
            {l[0]}
          tSpan(class="font-[sans-serif]"):
            {l[1]}


component LanguageMenu:
  `template`:
    nim:
      let lang = @[("EN", "English"), ("RU", "Русский") , ("ZH", "中文")]
    tDiv(title="Change Language", class="dropdown dropdown-end"):
      tLable(tabindex="0", class="btn btn-ghost rounded-btn"):
        tI(class="fa-solid fa-language fa-lg")
      tDiv(class="dropdown-content bg-base-200 text-base-content rounded-box top-px mt-16 w-56 overflow-y-auto shadow"):
        tUl(class="menu menu-sm gap-1", tabindex="0"):
          {menuList(lang)}