# NotchBar

App para macOS que convierte el notch del MacBook en un panel desplegable.

Al pasar el ratón por el notch se despliega un panel con:

- **Reloj y fecha**
- **Bandeja de archivos**: arrastra archivos al notch para guardarlos temporalmente; desde ahí puedes abrirlos, arrastrarlos a otra app o quitarlos con clic derecho.
- **Batería**: nivel y estado de carga.

En pantallas sin notch aparece una píldora negra en el centro del borde superior que se comporta igual.

## Requisitos

- macOS 13 o posterior
- Xcode 15 o posterior (o las Command Line Tools con Swift 5.9)

## Ejecutar

```bash
swift run
```

## Empaquetar como .app

```bash
./build-app.sh
open build/NotchBar.app
```

Para salir, usa el icono de NotchBar en la barra de menús → **Salir de NotchBar**.

## Estructura

| Archivo | Contenido |
| --- | --- |
| `main.swift`, `AppDelegate.swift` | Arranque e icono de la barra de menús |
| `NotchController.swift` | Ventana sobre el notch, geometría y despliegue con el ratón |
| `NotchModel.swift` | Estado compartido (desplegado, tamaño, bandeja) |
| `NotchView.swift` | Interfaz SwiftUI: silueta, reloj, bandeja y batería |
| `BatteryMonitor.swift` | Lectura de la batería con IOKit |
