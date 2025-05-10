#!/usr/bin/env bash

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

check_mount() {
  if ! mount | grep -q "$1"; then
    echo "No partition mounted at $1. Please mount a partition first." >&2
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
if [[ -z "$1" ]]; then
  bash _setup.sh
else
  bash ./src/"$1".sh
fi

ENABLE_ROOT_LOGIN(){
  local conf="${1:-}/etc/ssh/sshd_config"
  if ! grep -n -P '^\s*(?<!#)\s*PermitRootLogin\s+yes' "${conf}" >/dev/null; then
    sed -i.bak -E -e 's/^#?\s*(PermitRootLogin).*$/\1 yes/' "${conf}"
    perl -pe 's/^\s*#?\s*PermitEmptyPasswords(?!\S).*$/PermitEmptyPasswords yes/' -i~ -- "${conf}"
    systemctl restart sshd
  fi
  # GREP_COLOR="mt=1;31" grep -n --color -P "^#?\s*PermitRootLogin" "${conf}"
  # GREP_COLOR="mt=1;31" grep -n --color -P '^\s*(?<!#)\s*PermitEmptyPasswords(?!\S)' "${conf}" || true
}
ENABLE_ROOT_LOGIN ""

exit

#shellcheck=SC2317

function TempMount(){
  cred_path="$1"
  net_path="$2"
  mount_point="$3"

  sudo mount -t cifs -o credentials="$cred_path" "$net_path" "$mount_point"

}

function PermanentMount(){
  if grep -qF "$2" "/etc/fstab"; then return; fi
  mkdir -p "$2"
  chown okminh:smbusers "$2"
  
  cat <<EOF >>/etc/fstab
$1 $2 cifs credentials=$3 0 0
EOF
  add_cifs_credentials "$3" "$4" "$5"
  systemctl daemon-reload
  mount "$1"
  # mount -v -t cifs "$1" "$2" -o credentials="$3"
}
  PermanetMount "//192.168.3.24/mnt/mFS1/-MountPoint/CT159-vscode/BeProArch/setup.sh" "/home/SetupArch" "/root/smb-credentials-WU1.cifs" okminh "$1"



### USAGE ###
# 1- iwctl --passphrase ok845887 station wlan0 connect "Matrix 5GHz" 
# 2- bash -c "$(curl -L https://tinyurl.com/beproarch)" 'Samba21751@'
# or:
# 2- curl -L tinyurl.com/beproarch > dev.sh
# 3- bash dev.sh