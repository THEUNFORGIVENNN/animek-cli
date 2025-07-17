#!/bin/bash
# INI GRATIS KOK, SILAHKAN BOLEH DIMODIPIKASI LAGI

# Warna
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

CHANNEL_ID="UCVg6XW6LiG8y7ZP5l9nN3Rw"  # Muse Indonesia
MAX_RESULTS=20

echo -e "${CYAN}╭──────────────────────────────────────────────╮"
echo -e "│        ${BOLD}PENCARIAN ANIMEK - SUB INDO${RESET}${CYAN}        │"
echo -e "╰──────────────────────────────────────────────╯${RESET}"
echo -ne "${YELLOW}[?] Masukkin judul anime: ${RESET}"
read query

if [[ -z "$query" ]]; then
    echo -e "${RED}[!] Masukkin dong ganteeengg ${RESET}"
    exit 1
fi

echo -e "${CYAN}[~] Mencari \"$query\" di channel Muse Indonesia...${RESET}"

# nyari pidio disini
results=$(yt-dlp "ytsearch${MAX_RESULTS}:${query} site:youtube.com/channel/${CHANNEL_ID}" --print "%(title)s|%(id)s" --quiet)

if [[ -z "$results" ]]; then
    echo -e "${RED}[!] gada yang cocok maapin atmin yah.${RESET}"
    exit 1
fi

# Hasil disini
IFS=$'\n' read -rd '' -a lines <<<"$results"
echo -e "\n${GREEN}[+] Ditemukan ${#lines[@]} hasil:${RESET}"
echo -e "${CYAN}──────────────────────────────────────────────${RESET}"
for i in "${!lines[@]}"; do
    title="${lines[$i]%%|*}"
    printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "$title"
done
echo -e "${CYAN}──────────────────────────────────────────────${RESET}"

# Pilih Animek
echo -ne "${YELLOW}[?] Pilih video [1-${#lines[@]}]: ${RESET}"
read choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#lines[@]}" ]; then
    echo -e "${RED}[!] Pilihan tidak valid.${RESET}"
    exit 1
fi

video_id="${lines[$((choice-1))]##*|}"
url="https://www.youtube.com/watch?v=${video_id}"

echo -e "${GREEN}[▶] Memutar:${RESET} $url\n"
mpv --no-terminal --ytdl-format="bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" "$url"
# buat sekarang baru ada yt, ntar lu bisa modip lagi/tambahin platform lain, OKE!?
# kalo lu pake vlc bisa lu kasi fitur vlc atau kasi juga resolusi
