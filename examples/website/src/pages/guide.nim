import
  ../../../../src/happyx,
  ../path_params,
  ../components/[header, smart_card, card, section, code_block, about_section, drawer, sidebar, guide_page],
  ../ui/colors,
  json,
  os


mount UserGuide:
  "/{link?=introduction}":
    tDiv(class = "flex flex-col min-h-screen w-full bg-[{Background}] dark:bg-[{BackgroundDark}] text-[{Foreground}] dark:text-[{ForegroundDark}]"):
      nim:
        enableRouting = false
        currentGuidePage.set(link)
        enableRouting = true
      # Drawer
      component drawer_comp
      # Header
      tDiv(class = "w-full sticky top-0 z-20"):
        component Header(drawer = drawer_comp)
      tDiv(class = "flex w-full h-full gap-8 px-4"):
        # SideBar
        tDiv(class = "fixed top-0 pt-16 w-80"):
          component SideBar
        tDiv(class = "pl-0 xl:pl-80 w-full"):
          component GuidePage(link)
      tStyle:
        {fmt"""
          p:has(img[alt="Happyx"]) {{
            display: flex;
            justify-content: center;
            items-align: center;
          }}
          li {{
            list-style-type: disc;
            list-style-position: inside;
          }}
          ul {{
            display: flex;
            flex-direction: column;
            gap: .75rem;
          }}
          a {{
            display: inline-block;
            transition: colors;
            color: {LinkForeground};
          }}
          a:active {{
            color: {LinkActiveForeground};
          }}
          a:visited {{
            color: {LinkVisitedForeground};
          }}

          td {{
            padding: .2rem .4rem;
            display: table-cell;
            vertical-align: middle;
          }}
          
          @media (prefers-color-scheme: light) {{
            tr:nth-child(even) {{
              background: {Foreground}20;
            }}
            tr:nth-child(odd) {{
              background: {Foreground}15;
            }}
            tr {{
              border: 1px solid {Foreground}45;
            }}
          }}
          @media (prefers-color-scheme: dark) {{
            tr:nth-child(even) {{
              background: {ForegroundDark}20;
            }}
            tr:nth-child(odd) {{
              background: {ForegroundDark}15;
            }}
            tr {{
              border: 1px solid {ForegroundDark}45;
            }}
          }}
        """}
