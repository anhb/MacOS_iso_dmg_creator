# 🍎 MacOS_iso_dmg_creator
Automatiza la creación de archivos de imagen de disco (DMG y/o ISO) a partir de las aplicaciones de instalación de MacOS 
descargadas de la AppStore ubicadas en tu carpeta /Applications.

## 🧭 Tabla de Contenidos
1. 📜[Descripción](#Descripción)
2. 🚀[Requisitos](#Requisitos)
3. ⚙️[Uso](#Uso)
   1. [Modo Interactivo (Menú)](#Modo-Interactivo-Menú)
   2. [Modo Opciones (CLI)](#Modo-Opciones-CLI)
4. 🛠️[Script y Comandos](#Script-y-Comandos)
5. 📄[Versiones Soportadas](#Versiones-Soportadas)
6. 🙋‍♂️[Autor](#Autor)

## 📜Descripción
Este script de Zsh/Bash simplifica el proceso manual de crear medios de instalación de MacOS. Utiliza las herramientas 
nativas de MacOS **(*hdiutil*, *du*, *createinstallmedia*)** sin alteración de herramientas externas para:

- Detectar la versión de MacOS disponible en /Applications.
- Calcular automáticamente el tamaño necesario del disco con un buffer de seguridad (aproximadamente +2GB).
- Crear una imagen de disco temporal (.dmg) y montar el volumen.
- Ejecutar el comando createinstallmedia para escribir los archivos de instalación en la imagen montada.
- Desmontar y, opcionalmente, convertir la imagen final a formato ISO/CDR (ideal para máquinas virtuales como VMware o VirtualBox).

## 🚀Requisitos
1. **Sistema Operativo**: MacOS (funciona mejor en versiones recientes, ya que el shell predeterminado es Zsh).
2. **Permisos**: Se solicitará sudo durante el paso de createinstallmedia para asegurar permisos de escritura correctos en el volumen.
3. **Aplicación de Instalación**: La aplicación de instalación de MacOS debe estar descargada y ubicada en la carpeta */Applications* (ej: */Applications/Install MacOS Sonoma.app*).
Si aun no lo tienes descargadas, visita la [página oficial de Apple](https://support.apple.com/es-lamr/102662) en el apartado
"**Usar Appstore**" para seleccionar la version que quieres descargar y crear su imagen.

## ⚙️Uso
Asegúrate de que el script tenga permisos de ejecución:

> chmod +x macos_creator.sh

El script se puede ejecutar en modo interactivo o pasándole opciones por línea de comandos.

### Modo Interactivo (Menú)
Simplemente ejecute el script sin argumentos. El script le guiará paso a paso:

> ./macos_creator.sh

Flujo:
1. El script listará las versiones disponibles en /Applications.
2. Le pedirá que seleccione un número para la versión deseada.
3. Le preguntará si desea generar Solo DMG o DMG&ISO.
4. Comenzará el proceso automáticamente.
5. Una vez llegado al proceso de **createinstallmedia** se le solicítara su password para ejecutar el comando sudo.
6. Los archivos son almacenados en el directorio **~/Documents** por defecto.

### Modo Opciones (CLI)
Para uso avanzado o automatización, puede pasar las variables necesarias directamente al script.

| Opción | Argumento | Descripción | Obligatorio | Por Defecto |
| :--- | :--- | :--- | :--- | :--- |
| **-v** | `<VersionName>` | Nombre de la versión de macOS (ej: Sequoia, Monterey). | Sí | N/A |
| **-f** | `<Format>` | Formato de salida deseado. | No | `DMG_ISO` |
| **-o** | `<OutputPath>` | Ruta completa de salida para guardar los archivos. | No | `~/Documents/` |

#### Ejemplos:
1. Crear DMG e ISO de Sonoma en la ruta por defecto:
    > ./macos_creator.sh -v Sonoma -f DMG_ISO
2. Crear solo la imagen DMG de High Sierra, guardada en el Escritorio:
    > ./macos_creator.sh -v "High Sierra" -f DMG -o ~/Desktop/

## 🛠️Script y Comandos
El script automatiza la siguiente secuencia de comandos, utilizando las variables dinámicas calculadas:

| Paso | Comando Base | Propósito |
| :---: | :--- | :--- |
| **1.** | `hdiutil create` | Crea una imagen de disco en blanco (`.dmg`) con el tamaño calculado. |
| **2.** | `hdiutil attach` | Monta la imagen en `/Volumes/VersionName`. |
| **3.** | `sudo createinstallmedia` | Escribe los archivos de arranque del instalador en el volumen montado. |
| **4.** | `hdiutil detach` | Desmonta el volumen, finalizando el archivo `.dmg`. |
| **5.** | `hdiutil convert` | Convierte el `.dmg` al formato `UDTO` (compatible con ISO). |
| **6.** | `mv` | Renombra el archivo `.cdr` resultante a `.iso`. |


## 📄Versiones Soportadas
El script está configurado para buscar las siguientes aplicaciones en su carpeta /Applications:

| Nombre Visible (`-v` option) | Nombre de la Aplicación (Ruta) |
| :--- | :--- |
| **Sequoia** | `Install macOS Sequoia.app` |
| **Sonoma** | `Install macOS Sonoma.app` |
| **Ventura** | `Install macOS Ventura.app` |
| **Monterey** | `Install macOS Monterey.app` |
| **Big Sur** | `Install macOS Big Sur.app` |
| **Catalina** | `Install macOS Catalina.app` |
| **Mojave** | `Install macOS Mojave.app` |
| **High Sierra** | `Install macOS High Sierra.app` |

(*Si su aplicación de instalación tiene un nombre diferente, simplemente edite el array MACOS_VERSIONS dentro del script.*)

## 🙋‍♂️Autor

**Antony Hernandez** – *Autor y CEO de Anbytte*

Mis redes sociales son conocidas bajo el alias **bleakmurder**.

* [Sitio Web de la Empresa (Anbytte)](https://www.anbytte.com)
* [Perfil de Linkedin (Antony Hernandez)](https://www.linkedin.com/in/anhb96)  *(Ajusta este enlace a tu perfil real)*
* [Tik Tok (bleakmurder)](https://www.tiktok.com/@anhb96)
