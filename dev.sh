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

add_cifs_credentials(){
  cat <<EOF >"$1"
user=$2
password=$3
EOF
}

cred_path="${HOME}/.smbcredentials"

if [[ ! -e "$cred_path" ]]; then
  echo 'Account to access local network share:'
  NET_USER="$(tui::ask "Username: ")"
  NET_PASS="$(tui::ask "Password: ")"
  add_cifs_credentials $cred_path $NET_USER $NET_PASS
fi

# Check if a partition is mounted
check_mount() {
    if ! mount | grep -q "$1"; then
        error_msg "No partition mounted at $1. Please mount a partition first."
        return 1
    fi
    return 0
}

net_path="//192.168.3.24/mnt/mFS1/-MountPoint/CT159-vscode/BeProArch"
mount_point="/home/TempMount"

if ! check_mount "$mount_point"; then
  echo "Mounting..."
  mkdir -p "$mount_point"
  sudo mount -t cifs -o credentials="$cred_path" "$net_path" "$mount_point"
fi

local_dev="$HOME/BeProArch"
mkdir -p "$local_dev"
cp -R --update -f "$mount_point"/* "$local_dev"
cd "$local_dev"
bash setup.sh


__step "## Enable root passwordless login over SSH (for Dev)"  -----------------
ENABLE_ROOT_LOGIN(){
  local conf="${1:-}/etc/ssh/sshd_config"
  if ! grep -n -P '^\s*(?<!#)\s*PermitRootLogin\s+yes' "${conf}" >/dev/null; then
    sed -i.bak -E -e 's/^#?\s*(PermitRootLogin).*$/\1 yes/' "${conf}"
    perl -pe 's/^\s*#?\s*PermitEmptyPasswords(?!\S).*$/PermitEmptyPasswords yes/' -i~ -- "${conf}"
    systemctl restart sshd
  fi
  GREP_COLOR="mt=1;31" grep -n --color -P "^#?\s*PermitRootLogin" "${conf}"
  GREP_COLOR="mt=1;31" grep -n --color -P '^\s*(?<!#)\s*PermitEmptyPasswords(?!\S)' "${conf}" || true
}
ENABLE_ROOT_LOGIN ""
