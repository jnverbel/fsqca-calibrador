# Punto de entrada en la raiz.
#
# La interfaz vive en app/app.R y exige que el directorio de trabajo sea la
# raiz del repositorio: el .Rprofile que activa renv esta aqui, y sin el no
# se encuentran ni shiny ni QCA.
#
# shiny::runApp() fija el directorio de trabajo al del propio app.R, asi que
# teniendo este fichero en la raiz todo lo de abajo encuentra sus rutas. Es
# tambien lo que permite que shinytest2 abra la aplicacion de verdad en un
# navegador, cosa que no era posible mientras el unico punto de entrada
# estuviera dentro de app/.
#
# El `sys.nframe()` de app/app.R impide que esto arranque un segundo
# servidor: al llegar aqui por source(), no se cumple.

source(file.path("app", "app.R"))

shiny::shinyApp(ui, server)
