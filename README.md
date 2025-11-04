# 🍎 MacOS_iso_dmg_creator
Automatiza la preparación y creación de archivos de imagen de disco (DMG y/o ISO) a partir de instaladores de macOS, incluyendo la gestión de versiones Legacy.

## 🧭 Tabla de Contenidos
1. 📜[Descripción](#Descripción)
2. ✨[Nuevas Funcionalidades](#Nuevas-Funcionalidades)
3. 🚀[Requisitos](#Requisitos)
4. ⚙️[Uso](#Uso)
   1. [Modo Interactivo (Menú)](#Modo-Interactivo-Menú)
   2. [Modo Opciones (CLI)](#Modo-Opciones-CLI)
5. 🛠️[Script y Comandos](#Script-y-Comandos)
6. 📄[Versiones Soportadas](#Versiones-Soportadas)
7. 🙋‍♂️[Autor](#Autor)

## 📜Descripción
Este script de Zsh/Bash simplifica el proceso manual de crear medios de instalación de MacOS. Utiliza las herramientas nativas de MacOS **(*hdiutil*, *du*, *createinstallmedia*, *pkgutil*)** para gestionar tres flujos principales: Descarga, Preparación (Legacy) y Creación.

El script es capaz de:

- **Descargar** versiones modernas (vía `softwareupdate`) y versiones antiguas (DMG directo de Apple).
- **Instalar** la aplicación de instalación final dentro de `/Applications` a partir de los archivos DMG Legacy descargados.
- **Crear** imágenes de disco booteables (DMG/ISO) a partir de cualquier instalador ubicado en `/Applications`.

## ✨Nuevas Funcionalidades
Las últimas implementaciones añaden soporte completo para versiones antiguas de macOS (Legacy):

1.  **Descarga de Legacy DMGs**: Opción para descargar archivos DMG de instaladores antiguos (Lion a Sierra) directamente desde los servidores de Apple. Los archivos se guardan en `~/Documents/`.
2.  **Instalación de Legacy Aplicaciones**: Opción dedicada para montar un DMG Legacy (ej: `macOS_Sierra.dmg`) y ejecutar el `.pkg` interno para colocar la aplicación de instalación final (`Install macOS Sierra.app`) dentro de `/Applications`.
3.  **Soporte de `createinstallmedia` Legacy**: El proceso de creación (Opción 3) detecta automáticamente si la versión es Legacy (Sierra, El Capitan, Yosemite, etc.) y usa la sintaxis correcta del comando `createinstallmedia` (añadiendo el argumento `--applicationpath`).

## 🚀Requisitos
1. **Sistema Operativo**: MacOS (funciona mejor en versiones recientes, ya que el shell predeterminado es Zsh).
2. **Permisos**: Se solicitará `sudo` durante la instalación de paquetes (`.pkg`) y en el paso de `createinstallmedia`.
3. **Herramientas**: `curl` o `wget` para la descarga de DMGs Legacy.

## ⚙️Uso
El script se puede ejecutar en modo interactivo o pasándole opciones por línea de comandos.

### Modo Interactivo (Menú)
Simplemente ejecute el script sin argumentos. El script le guiará paso a paso a través de las tres opciones principales:

> ./macos_image_creator.sh

#### Flujo del Menú Principal:

| Opción | Descripción | Función |
| :--- | :--- | :--- |
| **1) Descargar macOS** | Descarga instaladores modernos (`softwareupdate`) o archivos DMG Legacy (`curl/wget`). | Obtiene el instalador. |
| **2) Instalar instalador Legacy** | Monta un DMG descargado y ejecuta su `.pkg` interno. | Coloca la aplicación final en `/Applications`. **(Requerido para Legacy)** |
| **3) Crear DMG/ISO** | Crea la imagen de disco booteable a partir de un instalador en `/Applications`. | Procesa la imagen final. |

### Modo Opciones (CLI)
Este modo es compatible únicamente con la **Opción 3 (Crear DMG/ISO)**, asumiendo que la aplicación de instalación ya se encuentra en `/Applications`.

| Opción | Argumento | Descripción | Obligatorio | Por Defecto |
| :--- | :--- | :--- | :--- | :--- |
| **-v** | `<VersionName>` | Nombre de la versión de macOS (ej: Sequoia, Sierra, Monterey). | Sí | N/A |
| **-f** | `<Format>` | Formato de salida deseado. | No | `DMG_ISO` |
| **-o** | `<OutputPath>` | Ruta completa de salida para guardar los archivos. | No | `~/Documents/` |

#### Ejemplos:
1. Crear DMG e ISO de Ventura en la ruta por defecto:
    > ./macos_creator.sh -v Ventura -f DMG_ISO
2. Crear solo la imagen DMG de Sierra, guardada en el Escritorio (asumiendo que `Install macOS Sierra.app` está en /Applications):
    > ./macos_creator.sh -v Sierra -f DMG -o ~/Desktop/

## 🛠️Script y Comandos
El script automatiza la siguiente secuencia de comandos para la **Creación de Imágenes Booteables**:

| Paso | Comando Base | Propósito |
| :---: | :--- | :--- |
| **1.** | `hdiutil create` | Crea una imagen de disco en blanco (`.dmg`) con el tamaño calculado. |
| **2.** | `hdiutil attach` | Monta la imagen en `/Volumes/VersionName`. |
| **3.** | `sudo createinstallmedia` | Escribe los archivos de arranque del instalador en el volumen montado (ajustando la sintaxis para versiones Legacy). |
| **4.** | `hdiutil detach` | Desmonta el volumen, finalizando el archivo `.dmg`. |
| **5.** | `hdiutil convert` | Convierte el `.dmg` al formato `UDTO` (compatible con ISO). |
| **6.** | `mv` | Renombra el archivo `.cdr` resultante a `.iso`. |


## 📄Versiones Soportadas
El script soporta y gestiona la lógica de instalación/creación para todas estas versiones:

| Nombre Visible (`-v` option) | Nombre de la Aplicación (Ruta) | Tipo |
| :--- | :--- | :--- |
| **Tahoe** | `Install macOS Tahoe.app` | Moderno |
| **Sequoia** | `Install macOS Sequoia.app` | Moderno |
| **Sonoma** | `Install macOS Sonoma.app` | Moderno |
| **Ventura** | `Install macOS Ventura.app` | Moderno |
| **Monterey** | `Install macOS Monterey.app` | Moderno |
| **Big Sur** | `Install macOS Big Sur.app` | Moderno |
| **Catalina** | `Install macOS Catalina.app` | Moderno |
| **Mojave** | `Install macOS Mojave.app` | Moderno |
| **High Sierra** | `Install macOS High Sierra.app` | Moderno |
| **Sierra** | `Install macOS Sierra.app` | **Legacy** |
| **El Capitan** | `Install OS X El Capitan.app` | **Legacy** |
| **Yosemite** | `Install OS X Yosemite.app` | **Legacy** |
| **Mountain Lion** | `Install OS X Mountain Lion.app` | **Legacy** |
| **Lion** | `Install Mac OS X Lion.app` | **Legacy** |

## 🙋‍♂️Autor

**Antony Hernandez** – *Autor y CEO de Anbytte*

Mis redes sociales son conocidas bajo el alias **bleakmurder**.

* [Sitio Web de la Empresa (Anbytte)](https://www.anbytte.com)
* [Perfil de Linkedin (Antony Hernandez)](https://www.linkedin.com/in/anhb96)
* [Tik Tok (bleakmurder)](https://www.tiktok.com/@anhb96)
