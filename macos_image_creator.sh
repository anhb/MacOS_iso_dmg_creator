#!/usr/bin/env zsh

if [[ -n "$ZSH_VERSION" ]]; then
    :
elif [[ -n "$BASH_VERSION" ]]; then
    shopt -s assoc_array_safe
else
    echo "ERROR: Solo se soportan Zsh y Bash."
    exit 1
fi

CURRENT_USER=$(whoami)
DEFAULT_OUTPUT_PATH="${HOME}/Documents"

declare -A MACOS_VERSIONS
MACOS_VERSIONS=(
    "Tahoe"                "Install macOS Tahoe.app"
    "Sequoia"              "Install macOS Sequoia.app"
    "Sonoma"               "Install macOS Sonoma.app"
    "Ventura"              "Install macOS Ventura.app"
    "Monterey"             "Install macOS Monterey.app"
    "Big Sur"              "Install macOS Big Sur.app"
    "Catalina"             "Install macOS Catalina.app"
    "Mojave"               "Install macOS Mojave.app"
    "High Sierra"          "Install macOS High Sierra.app"
    "Sierra"               "Install macOS Sierra.app"
    "El Capitan"           "Install OS X El Capitan.app"
    "Yosemite"             "Install OS X Yosemite.app"
    "Mountain Lion"        "Install OS X Mountain Lion.app"
    "Lion"                 "Install Mac OS X Lion.app"
)

declare -A LEGACY_MACOS_URLS
LEGACY_MACOS_URLS=(
    "Sierra_10.12"           "http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg"
    "El_Capitan_10.11"       "http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg"
    "Yosemite_10.10"         "http://updates-http.cdn-apple.com/2019/cert/061-41343-20191023-02465f92-3ab5-4c92-bfe2-b725447a070d/InstallMacOSX.dmg"
    "Mountain_Lion_10.8"     "https://updates.cdn-apple.com/2021/macos/031-0627-20210614-90D11F33-1A65-42DD-BBEA-E1D9F43A6B3F/InstallMacOSX.dmg"
    "Lion_10.7"              "https://updates.cdn-apple.com/2021/macos/041-7683-20210614-E610947E-C7CE-46EB-8860-D26D71F0D3EA/InstallMacOSX.dmg"
)

TARGET_VERSION=""
OUTPUT_PATH="${DEFAULT_OUTPUT_PATH}"
OUTPUT_TYPE="DMG_ISO"


download_legacy_macos() {
    echo "\n================================================="
    echo "  2. DESCARGA DE VERSIONES ANTIGUAS (DMG Directo)"
    echo "================================================="
    echo "-> Seleccione la versión Legacy a descargar:"

    local i=1
    local version_names=()
    for name in "${(@k)LEGACY_MACOS_URLS}"; do
        version_names+=("$name")
        echo "  $i) $name"
        i=$((i+1))
    done
    echo "  0) Cancelar y volver al menú principal"

    read -r "DL_CHOICE?Ingrese el número de la versión: "

    if [ "$DL_CHOICE" -eq 0 ]; then
        return 0
    fi

    local index=$((DL_CHOICE))
    local version_name="${version_names[$index]}"
    local download_url="${LEGACY_MACOS_URLS[$version_name]}"

    if [[ -z "$download_url" ]]; then
        echo "\nERROR: Opción no válida."
        return 1
    fi

    mkdir -p "${OUTPUT_PATH}"

    local filename=$(basename "$download_url")
    local output_file="${OUTPUT_PATH}/macOS_${version_name}_${filename}"

    echo "\n-> Iniciando descarga de ${version_name} desde Apple..."
    echo "   Se guardará en: ${output_file}"

    if command -v curl >/dev/null 2>&1; then
        echo "Usando curl para la descarga..."
        curl -L -o "$output_file" "$download_url" || { echo "\nERROR: Falló la descarga con curl." ; return 1; }
    elif command -v wget >/dev/null 2>&1; then
        echo "Usando wget para la descarga..."
        wget -O "$output_file" "$download_url" || { echo "\nERROR: Falló la descarga con wget." ; return 1; }
    else
        echo "\nERROR: Necesitas instalar 'curl' o 'wget' para descargar versiones antiguas."
        return 1
    fi

    echo "\n¡ÉXITO! DMG de ${version_name} descargado en ${OUTPUT_PATH}"
}

download_macos_installer() {
    echo "\n================================================="
    echo "  1. DESCARGA DE INSTALADORES (softwareupdate)"
    echo "================================================="

    echo "-> Listando versiones disponibles (puede tardar unos segundos)..."

    local update_list=$(softwareupdate --list-full-installers 2>/dev/null)
    local IFS=$'\n'
    local installer_lines=($(echo "$update_list" | grep 'Title:'))

    unset IFS

    if [ ${#installer_lines[@]} -eq 0 ]; then
        echo "\nADVERTENCIA: No se encontraron instaladores completos de macOS disponibles."
        echo "Asegúrese de que el comando 'softwareupdate --list-full-installers' funcione correctamente."
        return 1
    fi

    echo "\nVersiones de macOS disponibles para descargar:"
    local i=1
    local version_details=()

    for line in "${installer_lines[@]}"; do
        local title=$(echo "$line" | awk -F', ' '{for(i=1;i<=NF;i++) if($i ~ /Title:/) print $i}' | sed 's/.*Title: //; s/ *$//')
        local version=$(echo "$line" | awk -F', ' '{for(i=1;i<=NF;i++) if($i ~ /Version:/) print $i}' | sed 's/.*Version: //; s/ *$//')
        local build=$(echo "$line" | awk -F', ' '{for(i=1;i<=NF;i++) if($i ~ /Build:/) print $i}' | sed 's/.*Build: //; s/ *$//')

        version_details+=("$version")

        printf "  %s) %-15s Versión: %-10s Build: %s\n" "$i" "$title" "$version" "$build"

        i=$((i+1))
    done

    echo "  0) Cancelar y volver al menú principal"

    read -r "DL_CHOICE?Ingrese el número de la versión a descargar: "

    if [ "$DL_CHOICE" -eq 0 ]; then
        return 0
    fi

    local index=$((DL_CHOICE))
    local selected_version="${version_details[$index]}"
    if [[ -z "$selected_version" ]]; then
        echo "\nERROR: Opción no válida."
        return 1
    fi

    echo "\n-> Iniciando descarga de macOS versión $selected_version (se requerirá contraseña)..."
    echo "   La descarga se guardará en /Applications. Esto puede tardar mucho."

    sudo softwareupdate --fetch-full-installer --full-installer-version "$selected_version"

    if [ $? -eq 0 ]; then
        echo "\n¡ÉXITO! La aplicación de instalación para macOS $selected_version ha sido descargada a /Applications."
    else
        echo "\nERROR: Falló la descarga del instalador."
    fi
}

install_legacy_app() {
    echo "\n================================================="
    echo "  3. INSTALAR DMG LEGACY EN /Applications"
    echo "================================================="
    echo "-> Buscando archivos DMG de versiones Legacy en: ${DEFAULT_OUTPUT_PATH}/"

    local legacy_dmgs=($(find "${DEFAULT_OUTPUT_PATH}" -maxdepth 1 -name "macOS_*.dmg" -type f))

    if [ ${#legacy_dmgs[@]} -eq 0 ]; then
        echo "\nADVERTENCIA: No se encontraron archivos DMG de versiones Legacy ('macOS_*.dmg') en ${DEFAULT_OUTPUT_PATH}."
        echo "Use la Opción 1 (Descargar) para obtenerlos primero."
        return 0
    fi

    echo "\nArchivos DMG disponibles para instalar la aplicación:"
    local i=1
    local dmg_paths=()
    for dmg_file in "${legacy_dmgs[@]}"; do
        dmg_paths+=("$dmg_file")
        echo "  $i) $(basename "$dmg_file")"
        i=$((i+1))
    done
    echo "  0) Cancelar"

    read -r "CHOICE?Ingrese el número del archivo a instalar: "

    if [ "$CHOICE" -eq 0 ]; then
        return 0
    fi

    local index=$((CHOICE))
    local source_dmg_path="${dmg_paths[$index]}"

    if [[ -z "$source_dmg_path" ]]; then
        echo "\nERROR: Opción no válida."
        return 1
    fi

    local mount_point_dmg="/Volumes/DMG_Install_Temp"
    local pkg_path=""

    echo "\n-> 1/4: Montando el DMG: $(basename "$source_dmg_path")..."
    hdiutil attach "$source_dmg_path" -noverify -nobrowse -mountpoint "$mount_point_dmg" || { echo "ERROR: Falló hdiutil attach." ; return 1 ; }

    pkg_path=$(find "$mount_point_dmg" -maxdepth 2 -name "*.pkg" -print -quit 2>/dev/null)

    if [[ ! -f "$pkg_path" ]]; then
        echo "ERROR: No se encontró ningún paquete (.pkg) dentro del DMG montado."
        hdiutil detach "$mount_point_dmg" -force 2>/dev/null
        return 1
    fi

    echo "-> 2/4: Paquete encontrado: $(basename "$pkg_path")"
    echo "-> 3/4: Instalando paquete en /Applications (Se requerirá contraseña)..."

    sudo installer -pkg "$pkg_path" -target /

    local install_status=$?

    echo "-> 4/4: Desmontando DMG..."
    hdiutil detach "$mount_point_dmg" -force 2>/dev/null

    if [ $install_status -eq 0 ]; then
        echo "\n¡ÉXITO! La aplicación de instalación ha sido colocada en /Applications."
        echo "Ahora puede usar la Opción 2 del menú principal para crear el DMG/ISO."
    else
        echo "\nERROR: Falló la instalación del paquete."
        return 1
    fi
}

calculate_image_size() {
    local app_path="$1"
    local size_kb=$(du -s -k "${app_path}" | awk '{print $1}')

    if [[ ! "$size_kb" =~ ^[0-9]+$ ]]; then
        echo "ERROR CRÍTICO: No se pudo obtener el tamaño de la aplicación como un número entero."
        echo "Compruebe la ruta: ${app_path}"
        exit 1
    fi

    local size_mb=$(( size_kb / 1024 + 2096  ))
    echo "${size_mb}m"
}

get_build_version() {
    local app_path="$1"

    local version_info=$(defaults read "${app_path}/Contents/Info.plist" DTPlatformVersion 2>/dev/null)

    if [[ -n "$version_info" ]]; then
        echo "${version_info}"
    else
        echo "Desconocida"
    fi
}

execute_process() {
    local version_name="$1"
    local app_file_name="${MACOS_VERSIONS[$version_name]}"
    local path_macos_app="/Applications/${app_file_name}"

    local image_size=$(calculate_image_size "${path_macos_app}")
    local build_version=$(get_build_version "${path_macos_app}")
    local image_name="macOS_${version_name}_${build_version}"
    local mount_point="${app_file_name%.app}"

    echo "\n================================================="
    echo "  INICIANDO PROCESO PARA: ${version_name}"
    echo "================================================="
    echo "  App: ${path_macos_app}"
    echo "  Tamaño calculado: ${image_size}"
    echo "  Salida: ${OUTPUT_PATH}/${image_name}.dmg"
    echo "================================================="
    if [[ "$version_name" == "Mountain Lion" || \
          "$version_name" == "Lion" ]]; then

        local path_installesd=$(find "$path_macos_app" -maxdepth 5 -name "InstallESD.dmg" -print -quit 2>/dev/null)
        echo "${path_installesd}"
        echo "${image_name}"
        cp "${path_installesd}" "${OUTPUT_PATH}/"
        mv "${OUTPUT_PATH}/InstallESD.dmg" "${OUTPUT_PATH}/${image_name}.dmg"

    else
        if [[ "$version_name" == "Sierra" ]]; then
        sudo plutil -replace CFBundleShortVersionString -string "12.6.03" "${path_macos_app}/Contents/Info.plist"
        fi

        mkdir -p "${OUTPUT_PATH}"

        echo "\n-> 1/5: Creando la imagen de disco en blanco (.dmg)..."
        hdiutil create -o "${OUTPUT_PATH}/${image_name}" -size "${image_size}" -volname "${version_name}" -layout SPUD -fs HFS+J || { echo "ERROR: Falló hdiutil create." ; exit 1 ; }

        echo "\n-> 2/5: Montando la imagen en /Volumes/${version_name}..."
        hdiutil attach "${OUTPUT_PATH}/${image_name}.dmg" -noverify -mountpoint "/Volumes/${version_name}" || { echo "ERROR: Falló hdiutil attach." ; exit 1 ; }

        echo "\n-> 3/5: Creando el instalador de arranque (esto puede tardar varios minutos)..."
        if [[ "$version_name" == "Sierra" || \
            "$version_name" == "El Capitan" || \
            "$version_name" == "Yosemite" ]]; then

            echo "-> [MODO LEGACY ACTIVO]: Usando --applicationpath."
            sudo "${path_macos_app}/Contents/Resources/createinstallmedia" --volume "/Volumes/${version_name}" --applicationpath "${path_macos_app}" --nointeraction || { echo "ERROR: Falló createinstallmedia." ; exit 1 ; }

        else
            echo "-> [MODO MODERNO ACTIVO]: Comando estándar."
            sudo "${path_macos_app}/Contents/Resources/createinstallmedia" --volume "/Volumes/${version_name}" --nointeraction || { echo "ERROR: Falló createinstallmedia." ; exit 1 ; }

        fi

        echo "\n-> 4/5: Desmontando el volumen de instalación..."
        echo "hdiutil detach /Volumes/${mount_point} -force"
        hdiutil detach "/Volumes/${mount_point}" -force || { echo "ADVERTENCIA: Falló el desmontaje, puede ser normal." ; }

    fi

    if [[ "$OUTPUT_TYPE" == "DMG_ISO" ]]; then
        echo "\n-> 5/5: Creando la imagen ISO para VMware..."
        local cdr_path="${OUTPUT_PATH}/${image_name}.cdr"
        local iso_path="${OUTPUT_PATH}/${image_name}.iso"

        hdiutil convert "${OUTPUT_PATH}/${image_name}.dmg" -format UDTO -o "${cdr_path}" || { echo "ERROR: Falló hdiutil convert a CDR." ; exit 1 ; }

        mv "${cdr_path}" "${iso_path}" || { echo "ERROR: Falló el renombrado de CDR a ISO." ; exit 1 ; }

        echo "\n¡ÉXITO! Imágenes creadas:"
        echo "  - DMG de Arranque: ${OUTPUT_PATH}/${image_name}.dmg"
        echo "  - ISO para VMware: ${OUTPUT_PATH}/${image_name}.iso"
    else
        echo "\n¡ÉXITO! Imagen DMG de Arranque creada:"
        echo "  - DMG de Arranque: ${OUTPUT_PATH}/${image_name}.dmg"
    fi
}

parse_options() {
    while getopts "v:f:o:" opt; do
        case "$opt" in
            v) TARGET_VERSION="$OPTARG" ;;
            f) OUTPUT_TYPE=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]')
               if [[ "$OUTPUT_TYPE" != "DMG" && "$OUTPUT_TYPE" != "DMG_ISO" ]]; then
                   echo "ERROR: Formato (-f) debe ser 'dmg' o 'dmg_iso'."
                   exit 1
               fi
               ;;
            o) OUTPUT_PATH="$OPTARG" ;;
            \?) echo "Uso: $0 -v <Version> [-f <DMG|DMG_ISO>] [-o <RutaSalida>]"
                echo "Versiones soportadas: ${(@k)MACOS_VERSIONS}"
                exit 1
                ;;
        esac
    done
}

show_interactive_menu() {
    echo "\n================================================="
    echo "  1. CREAR DMG/ISO (Instalador en /Applications)"
    echo "================================================="
    echo "Por favor, seleccione la versión de macOS instalada en /Applications:"

    local i=1
    local version_names=()
    for name in "${(@k)MACOS_VERSIONS}"; do
        version_names+=("$name")
        if [[ -e "/Applications/${MACOS_VERSIONS[$name]}" ]]; then
            echo "  $i) $name (Disponible)"
        else
            echo "  $i) $name (NO DISPONIBLE)"
        fi
        i=$((i+1))
    done

    read -r "CHOICE?Ingrese el número de la versión: "
    TARGET_VERSION="${version_names[$CHOICE]}"

    if [[ -z "$TARGET_VERSION" || -z "${MACOS_VERSIONS[$TARGET_VERSION]}" ]]; then
        echo "\nERROR: Opción no válida."
        exit 1
    fi
    if [[ ! -e "/Applications/${MACOS_VERSIONS[$TARGET_VERSION]}" ]]; then
        echo "\nERROR: La aplicación de instalación de $TARGET_VERSION no se encontró en /Applications."
        exit 1
    fi

    echo "\nSeleccione el formato de salida:"
    echo "  1) Solo DMG"
    echo "  2) DMG y ISO (Recomendado para Virtualizacion)"
    read -r "FORMAT_CHOICE?Ingrese el número del formato: "

    case "$FORMAT_CHOICE" in
        1) OUTPUT_TYPE="DMG" ;;
        2) OUTPUT_TYPE="DMG_ISO" ;;
        *) echo "\nERROR: Opción de formato no válida." ; exit 1 ;;
    esac
}

show_download_menu() {
    while true; do
        echo "\n================================================="
        echo "  1. MENÚ DE DESCARGA DE MACOS"
        echo "================================================="
        echo "Seleccione el método de descarga:"
        echo "  1) Descargar instalador de macOS (softwareupdate - macOS Only)"
        echo "  2) Descargar macOS Viejas Versiones (DMG Directo - macOS & Linux)"
        echo "  3) Volver al Menú Principal"

        read -r "SUB_CHOICE?Ingrese el número de la opción: "

        case "$SUB_CHOICE" in
            1)
                download_macos_installer
                ;;
            2)
                download_legacy_macos
                ;;
            3)
                return
                ;;
            *)
                echo "\nERROR: Opción no válida. Intente de nuevo."
                ;;
        esac
    done
}

show_creation_menu() {
    while true; do
        echo "\n================================================="
        echo "  3. MENÚ DE CREACIÓN DE DMG/ISO"
        echo "================================================="
        echo "Seleccione el método de creación de imagen:"
        echo "  1) Crear DMG/ISO (Desde un instalador existente en /Applications) [macOS Only]"
        echo "  2) Volver al Menú Principal"
        read -r "CREATE_CHOICE?Ingrese el número de la opción: "

        case "$CREATE_CHOICE" in
            1)
                show_interactive_menu
                execute_process "$TARGET_VERSION"
                return
                ;;
            2)
                return
                ;;
            *)
                echo "\nERROR: Opción no válida. Intente de nuevo."
                ;;
        esac
    done
}

show_main_menu() {
    while true; do
        echo "\n================================================="
        echo "  MACOS UTILITY CREATOR - Author: bleakmurder"
        echo "================================================="
        echo "Por favor, seleccione una opción:"
        echo "  1) Descargar macOS (Modernas / Viejas Versiones)"
        echo "  2) Instalar instalador Legacy desde DMG (DMG -> /Applications) [macOS Only]"
        echo "  3) Crear DMG/ISO"
        echo "  4) Salir"

        read -r "MAIN_CHOICE?Ingrese el número de la opción: "

        case "$MAIN_CHOICE" in
            1)
                show_download_menu
                ;;
            2)
                install_legacy_app
                ;;
            3)
                show_creation_menu
                ;;
            4)
                echo "Saliendo del script. ¡Adiós!"
                exit 0
                ;;
            *)
                echo "\nERROR: Opción no válida. Intente de nuevo."
                ;;
        esac
    done
}

if [[ $# -gt 0 ]]; then

    parse_options "$@"

    if [[ -z "$TARGET_VERSION" ]]; then
        echo "ERROR: Debe especificar la versión de macOS con -v."
        exit 1
    fi

    if [[ -z "${MACOS_VERSIONS[$TARGET_VERSION]}" ]]; then
        echo "ERROR: Versión no soportada o mal escrita: ${TARGET_VERSION}"
        echo "Versiones soportadas: ${(@k)MACOS_VERSIONS}"
        exit 1
    fi

    if [[ ! -e "/Applications/${MACOS_VERSIONS[$TARGET_VERSION]}" ]]; then
        echo "ERROR: La aplicación de instalación de ${TARGET_VERSION} no se encontró en /Applications. Asegúrese de que esté instalada."
        exit 1
    fi


    execute_process "$TARGET_VERSION"

else
    show_main_menu
fi
