#!/bin/zsh

CURRENT_USER=$(whoami)
DEFAULT_OUTPUT_PATH="/Users/${CURRENT_USER}/Documents"

declare -A MACOS_VERSIONS
MACOS_VERSIONS=(
    "Sequoia"              "Install macOS Sequoia.app"
    "Sonoma"               "Install macOS Sonoma.app"
    "Ventura"              "Install macOS Ventura.app"
    "Monterey"             "Install macOS Monterey.app"
    "Big Sur"              "Install macOS Big Sur.app"
    "Catalina"             "Install macOS Catalina.app"
    "Mojave"               "Install macOS Mojave.app"
    "High Sierra"          "Install macOS High Sierra.app"
)

TARGET_VERSION=""
OUTPUT_PATH="${DEFAULT_OUTPUT_PATH}"

# Valores: "DMG" o "DMG_ISO"
OUTPUT_TYPE="DMG_ISO"

show_interactive_menu() {
    echo "\n================================================="
    echo "  MACOS IMAGE CREATOR - Author: Bleakmurder"
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
    local mount_point="Install macOS ${version_name}"

    echo "\n================================================="
    echo "  INICIANDO PROCESO PARA: ${version_name}"
    echo "================================================="
    echo "  App: ${path_macos_app}"
    echo "  Tamaño calculado: ${image_size}"
    echo "  Salida: ${OUTPUT_PATH}/${image_name}.dmg"
    echo "================================================="
    
    mkdir -p "${OUTPUT_PATH}"
    
    echo "\n-> 1/5: Creando la imagen de disco en blanco (.dmg)..."
    hdiutil create -o "${OUTPUT_PATH}/${image_name}" -size "${image_size}" -volname "${version_name}" -layout SPUD -fs HFS+J || { echo "ERROR: Falló hdiutil create." ; exit 1 ; }
    
    echo "\n-> 2/5: Montando la imagen en /Volumes/${version_name}..."
    hdiutil attach "${OUTPUT_PATH}/${image_name}.dmg" -noverify -mountpoint "/Volumes/${version_name}" || { echo "ERROR: Falló hdiutil attach." ; exit 1 ; }

    echo "\n-> 3/5: Creando el instalador de arranque (esto puede tardar varios minutos)..."
    sudo "${path_macos_app}/Contents/Resources/createinstallmedia" --volume "/Volumes/${version_name}" --nointeraction || { echo "ERROR: Falló createinstallmedia." ; exit 1 ; }

    echo "\n-> 4/5: Desmontando el volumen de instalación..."
    hdiutil detach "/Volumes/${mount_point}" -force || { echo "ADVERTENCIA: Falló el desmontaje, puede ser normal." ; }

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
else
    show_interactive_menu
fi

execute_process "$TARGET_VERSION"
