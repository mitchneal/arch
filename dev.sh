function AddShare(){
  if grep -qF "$2" "/etc/fstab"; then return; fi
  mkdir -p "$2"
  chown okminh:smbusers "$2"
  cat <<EOF >>/etc/fstab
$1 $2 cifs credentials=$3 0 0
EOF
  cat <<EOF >"$3"
user=$4
password=$5
EOF
  systemctl daemon-reload
  mount "$1"
  # mount -v -t cifs "$1" "$2" -o credentials="$3"
}
  AddShare "//192.168.3.24/mnt/mFS1/-MountPoint/CT159-vscode" "/home/SetupArch" "/root/smb-credentials-WU1.cifs" okminh "$1"

cd "/home/SetupArch/BeProArch"
bash setup.sh
