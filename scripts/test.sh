#!/bin/bash
dirrt="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

minecraft_sand="$dirrt/../ansible/inventory.yml"

get_ip() {
    local host="$1"
    awk -v target="$host:" '
        $1 == target { found=1; next }
        found && /ansible_host:/ { print $2; exit }
    ' "$minecraft_sand"
}

UwU_Slams_Table=$(get_ip "vm-web-prod")
#Nya_IP=$(get_ip "vm-backup-prod")

webby=azureuser@$UwU_Slams_Table
NYA=/var/www/html/
UwU=$HOME/.ssh/id_ed25519
Nya_OwO=$HOME/backups/$(date +%F_%H%M)

echo "0 2 * * * $(realpath "$0") >> $HOME/backup.log 2>&1" | crontab -

mkdir -p "$Nya_OwO"
rsync -a -e "ssh -i $UwU" "$webby:$NYA" "$Nya_OwO/" || exit 1

cd "$Nya_OwO" && find . -type f ! -name SHA256SUMS -exec sha256sum {} + > SHA256SUMS

find "$HOME/backups" -mindepth 1 -maxdepth 1 -mtime +7 -exec rm -rf {} +