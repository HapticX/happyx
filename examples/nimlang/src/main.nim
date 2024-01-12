import
  ../../../src/happyx,
  path_params,
  components/components,
  pages/pages,
  app_config


appRoutes "app":
  "/":
    tDiv(class = "flex flex-col"):
      Header
      Overview
      
  "/blog":
    tDiv(class = "flex flex-col"):
      Header

  "/features":
    tDiv(class = "flex flex-col"):
      Header

  "/download":
    tDiv(class = "flex flex-col"):
      Header

  "/docs":
    tDiv(class = "flex flex-col"):
      Header

  "/forum":
    tDiv(class = "flex flex-col"):
      Header

  "/donate":
    tDiv(class = "flex flex-col"):
      Header

  "/source":
    tDiv(class = "flex flex-col"):
      Header
