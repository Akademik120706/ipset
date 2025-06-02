#!/bin/bash

# Naziv ipset liste
IPSET_NAME="bad_ips"

# GitHub RAW URL (prilagođeno)
GITHUB_RAW_URL="https://raw.githubusercontent.com/Akademik120706/ipset/main/ipset-backup.rules"

# Privremena lokacija
TMP_LIST="/tmp/ipset-backup.rules"

# Funkcija za instalaciju ako fali
install_if_missing() {
    if ! command -v "$1" &> /dev/null; then
        echo "[+] Instaliram $1..."
        apt update && apt install -y "$1"
    fi
}

# Provjera root pristupa
if [[ $EUID -ne 0 ]]; then
    echo "[!] Pokreni skriptu kao root."
    exit 1
fi

# Provjeri curl i ipset
install_if_missing curl
install_if_missing ipset

# Preuzimanje IP liste
echo "[+] Preuzimam IP listu s GitHuba..."
curl -s -o "$TMP_LIST" "$GITHUB_RAW_URL"

# Provjera da fajl nije prazan
if [[ ! -s "$TMP_LIST" ]]; then
    echo "[!] Greška: Lista nije preuzeta ili je prazna."
    exit 1
fi

# Ako lista već postoji – izbriši je
if ipset list -n | grep -q "^$IPSET_NAME$"; then
    echo "[*] Brišem postojeću ipset listu $IPSET_NAME..."
    ipset destroy "$IPSET_NAME"
fi

# Kreiraj novu listu
echo "[+] Kreiram novu ipset listu: $IPSET_NAME..."
ipset create "$IPSET_NAME" hash:net

# Uvoz IP adresa
echo "[+] Učitavam IP adrese u ipset..."
while read -r ip; do
    [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue
    ipset add "$IPSET_NAME" "$ip" 2>/dev/null
done < "$TMP_LIST"

# Provjera rezultata
TOTAL=$(ipset list "$IPSET_NAME" | grep -c '^    ')
echo "[✔] Uvezeno $TOTAL IP adresa u listu '$IPSET_NAME'."

# (Opcionalno) iptables pravilo
echo "[+] Dodajem iptables pravilo da se blokira pristup s tih IP-a..."
iptables -C INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || \
iptables -A INPUT -m set --match-set "$IPSET_NAME" src -j DROP

echo "[✔] Gotovo."
