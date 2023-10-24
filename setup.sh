#!/bin/sh

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or using sudo"
   exit 1
fi

if ! [ -x "$(command -v figlet)" ]; then
  read -p "Figlet not found, installing ... are you sure? " -n 1 -r
	echo    # (optional) move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
    apt install figlet
  fi
fi

if ! [ -x "$(command -v lsb_release)" ]; then
  apt install lsb-release
fi

cp ./update-motd.d/* /etc/update-motd.d/

mv /etc/motd /etc/motd.ORI
mv /etc/issue /etc/issue.ORI


cat <<'EOF' > /etc/network/if-up.d/update-issue
#!/bin/sh
#
#    update-issue - write info to /etc/issue at boot
#
set -e

HEADER=$(/etc/update-motd.d/00-header)
SYSINFO=$(/etc/update-motd.d/10-sysinfo)

echo "$HEADER\n\n$SYSINFO" > /etc/issue
EOF

chmod +x /etc/network/if-up.d/update-issue