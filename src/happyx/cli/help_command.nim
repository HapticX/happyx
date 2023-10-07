import
  random,
  ./utils


randomize()


proc mainHelpMessage*() =
  ## Shows the general help message that describes
  let
    subcommands = [
      "build", "dev", "serve", "create", "html2tag", "update", "help"
    ]
    logoColors = [
      fgBlue, fgGreen, fgYellow, fgWhite, fgCyan
    ]
    logoColor = logoColors[rand(0..logoColors.len - 1)]
    delimeter = ansiForegroundColorCode(fgWhite) & "|" & ansiForegroundColorCode(fgBlue)
    counterPath = getHomeDir() / ".nimble" / "bin" / "happyx"

  styledEcho logoColor, styleBright, """    __                                
   / /_  ____ _____  ____  __  ___  __
  / __ \/ __ `/ __ \/ __ \/ / / / |/_/
 / / / / /_/ / /_/ / /_/ / /_/  >""", fgRed, "//", logoColor, styleBright, "<  \n", ansiResetCode, logoColor, """
/_/ /_/\__,_/ .___/ .___/\__, /_/|_|  
           /_/   /_/    /____/        """
  styledEcho logoColor, align("v" & HpxVersion, 38)
  styledEcho(
    "\nCLI for ", fgGreen, "creating", fgWhite, ", ",
    fgGreen, "serving", fgWhite, " and ", fgGreen, "building",
    fgWhite, " HappyX projects\n"
  )
  styledEcho "Usage:"
  styledEcho fgMagenta, " hpx ", fgYellow, "help", fgBlue, "subcommand "
  styledEcho fgMagenta, " hpx ", fgBlue, subcommands.join(delimeter), fgYellow, " [subcommand-args]"
