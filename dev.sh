#!/usr/bin/env bash

__step=0
__step(){
  local step=""; [ -n "${2:-}" ] && { __step=$((__step+1)); step="[$__step]"; }
  [[ -z $step ]] && step="--$(printf '%.s-' $(seq 1 ${#__step}))"
  pad='------------------------------------------------------------------------'
  printf "\e[1;35m%s\e[0m %s${step} %s\n" "➧$1" "${pad:${#1}}" "${BASH_SOURCE[0]}" # • ${FUNCNAME[1]}
}

function tui::ask(){
  if [[ ${1:-} == "-p" ]]; then shift; fi
  local prompt="${1:-}"
  while true; do
    read -p "$prompt" -r reply
    [[ -z $reply ]] && { prompt="Again: " ; continue; }
    echo "$reply"
    break
  done
}

__step "## Copy files from local network"  -------------------------------------

# Ask for username
echo 'Account to access local network share:'
NET_USER="$(tui::ask "Username: ")"
NET_PASS="$(tui::ask "Password: ")"

add_cifs_credentials(){
  cat <<EOF >"$1"
user=$2
password=$3
EOF
}

cred_path="${HOME}/.smbcredentials"
add_cifs_credentials $cred_path $NET_USER $NET_PASS

net_path="//192.168.3.24/mnt/mFS1/-MountPoint/CT159-vscode/BeProArch"
mount_point="/home/TempMount"

mkdir -p "$mount_point"
sudo mount -t cifs -o credentials="$cred_path" "$net_path" "$mount_point"

local_dev="$HOME"

cp -R "$$mount_point" "$local_dev"
cd "$local_dev"
bash setup.sh
