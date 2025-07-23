#!/bin/bash
# INI GRATIS KOK, SILAHKAN BOLEH DIMODIFIKASI LAGI

#Script
SCRIPT_VERSION="1.0.0"

show_help() {
    echo -e "${BOLD}Penggunaan:${RESET} animek-cli [opsi]"
    echo -e "\n${BOLD}Opsi:${RESET}"
    echo -e "  --help       Menampilkan bantuan ini dan keluar"
    echo -e "  --version    Menampilkan versi script dan keluar"
    echo -e "\nContoh:"
    echo -e "  animek-cli"
}

show_version() {
    echo -e "animek-cli versi $SCRIPT_VERSION"
}

# Warna
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

CHANNEL_ID="UCVg6XW6LiG8y7ZP5l9nN3Rw"  # Muse Indonesia
MAX_RESULTS=20

#pemanggilan script
if [[ "$1" == "--help" ]]; then
    show_help
    exit 0
elif [[ "$1" == "--version" ]]; then
    show_version
    exit 0
fi


echo -e "${CYAN}╭──────────────────────────────────────────────╮"
echo -e "│        ${BOLD}PENCARIAN ANIMEK - SUB INDO${RESET}${CYAN}           │"
echo -e "╰──────────────────────────────────────────────╯${RESET}"

# Cek dependensi
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}[!] Error: $1 tidak terinstall.${RESET}"
        return 1
    fi
    return 0
}

if ! check_dependency "yt-dlp"; then
    echo -e "${YELLOW}Install dengan: pip3 install yt-dlp${RESET}"
    exit 1
fi

# Deteksi pemutar video
detect_player() {
    declare -A players
    players["mpv"]="mpv --no-terminal"
    players["vlc"]="vlc --play-and-exit --quiet"
    players["iina"]="iina --no-stdin"

    for player in "${!players[@]}"; do
        if command -v "$player" &> /dev/null; then
            echo "$player"
            return
        fi
    done
    echo ""
}

PLAYER_CMD=""
default_player=$(detect_player)
if [[ -z "$default_player" ]]; then
    echo -e "${RED}[!] Tidak ada pemutar video yang terdeteksi.${RESET}"
    echo -e "${YELLOW}Instal salah satu: mpv, vlc, atau iina${RESET}"
    exit 1
fi

# Fungsi pemilihan
select_option() {
    local prompt="$1"
    local options=("${@:2}")
    local selected=0

    while true; do
        echo -e "${YELLOW}$prompt${RESET}"
        for i in "${!options[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "${GREEN}  > $((i+1)). ${options[$i]}${RESET}"
            else
                echo "    $((i+1)). ${options[$i]}"
            fi
        done

        read -rsn1 input
        case "$input" in
            "A") # Up arrow
                selected=$(( (selected + ${#options[@]} - 1) % ${#options[@]} )) ;;
            "B") # Down arrow
                selected=$(( (selected + 1) % ${#options[@]} )) ;;
            "") # Enter
                return $((selected)) ;;
            [1-9]) # Number input
                if [[ $input -le ${#options[@]} ]]; then
                    return $((input-1))
                fi ;;
        esac
        tput cuu $((${#options[@]}+1))
    done
}

# Input judul
echo -ne "${YELLOW}[?] Masukkan judul anime: ${RESET}"
read -r query

if [[ -z "$query" ]]; then
    echo -e "${RED}[!] Masukkan dong ganteengg cantiikkk${RESET}"
    exit 1
fi

echo -e "${CYAN}[~] Mencari \"$query\" di channel Muse Indonesia...${RESET}"

# Nyari Pidio
results=$(yt-dlp "ytsearch$MAX_RESULTS:$query site:youtube.com/channel/$CHANNEL_ID" \
    --print "%(title)s|%(id)s|%(duration>%H:%M:%S)s" \
    --match-filter "duration < 3600" \
    --quiet 2>/dev/null)

if [[ -z "$results" ]]; then
    echo -e "${RED}[!] gada yang cocok maapin atmin yah.${RESET}"
    exit 1
fi

# Menampilkan hasil
mapfile -t lines <<< "$results"
echo -e "\n${GREEN}[+] Ditemukan ${#lines[@]} hasil:${RESET}"
echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

for i in "${!lines[@]}"; do
    IFS='|' read -r title id duration <<< "${lines[$i]}"
    printf "${BOLD}%2d${RESET}. %s ${CYAN}(%s)${RESET}\n" "$((i+1))" "$title" "$duration"
done
echo -e "${CYAN}──────────────────────────────────────────────────────${RESET}"

# Pemilihan video
selected_index=-1
while [[ $selected_index -lt 0 || $selected_index -ge ${#lines[@]} ]]; do
    echo -ne "${YELLOW}[?] Pilih video [1-${#lines[@]}]: ${RESET}"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        selected_index=$((choice-1))
    fi
done

IFS='|' read -r selected_title video_id duration <<< "${lines[$selected_index]}"
video_url="https://www.youtube.com/watch?v=$video_id"

# Pemilihan kualitas
echo -e "\n${GREEN}[~] Mendapatkan kualitas video...${RESET}"
formats=$(yt-dlp -F "$video_url" --quiet 2>/dev/null | grep -E "video only|audio only")

if [[ -z "$formats" ]]; then
    echo -e "${YELLOW}[!] Tidak dapat mendapatkan daftar kualitas. Gunakan kualitas default.${RESET}"
    selected_format="best"
else
    quality_options=("Kualitas terbaik (default)")
    format_ids=("best")
    
    while IFS= read -r line; do
        if [[ $line =~ ([0-9]+).*([0-9]{3,4}x[0-9]+).* ]]; then
            format_id="${BASH_REMATCH[1]}"
            resolution="${BASH_REMATCH[2]}"
            quality_options+=("$resolution")
            format_ids+=("$format_id")
        fi
    done <<< "$formats"
    
    select_option "[?] Pilih kualitas video:" "${quality_options[@]}"
    quality_choice=$?
    selected_format="${format_ids[$quality_choice]}"
fi

# Pemilihan pemutar
players=()
[[ -n "$default_player" ]] && players+=("$default_player")
[[ "$default_player" != "mpv" && $(command -v mpv) ]] && players+=("mpv")
[[ "$default_player" != "vlc" && $(command -v vlc) ]] && players+=("vlc")
[[ "$default_player" != "iina" && $(command -v iina) ]] && players+=("iina")

player_name="$default_player"
if [[ ${#players[@]} -gt 1 ]]; then
    select_option "[?] Pilih pemutar video:" "${players[@]}"
    player_choice=$?
    player_name="${players[$player_choice]}"
fi

# Konfigurasi pemutar
case "$player_name" in
    "mpv") player_cmd="mpv --no-terminal --ytdl-format=$selected_format" ;;
    "vlc") player_cmd="vlc --play-and-exit --quiet" ;;
    "iina") player_cmd="iina --no-stdin" ;;
    *) player_cmd="$player_name" ;;
esac

# Putar video
echo -e "\n${GREEN}[▶] Memutar:${RESET} $selected_title"
echo -e "${CYAN}[ℹ] Kualitas: ${BOLD}${quality_options[$quality_choice]}${RESET}"
echo -e "${CYAN}[ℹ] Pemutar: ${BOLD}$player_name${RESET}\n"

if ! $player_cmd "$video_url"; then
    echo -e "\n${RED}[!] Gagal memutar video.${RESET}"
    echo -e "${YELLOW}Mungkin perlu instal codec tambahan atau coba pemutar lain.${RESET}"
    exit 1
fi

exit 0
# Sosok Atmin: buat sekarang baru ada yt, ntar lu bisa modip lagi/tambahin platform lain, OKE!?
# Ryoukaii: OKE! dah gweh tambahin nih, mayan banyak lah fitur yg gweh tambahin
# Sosok Atmin: kalo lu pake vlc bisa lu kasi fitur vlc atau kasi juga resolusi
# Ryoukaii: OKE! gweh tambahin vlc nih sama iina