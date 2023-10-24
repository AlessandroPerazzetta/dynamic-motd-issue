#!/bin/bash

OS_ID=""
MOTD_PATH=/etc/update-motd.d/

function is_root {
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run as root or using sudo"
     exit 1
  fi
}

# Check dependencies
function check_dependencies {
    echo "Checking dependencies ..."
    deps=("lsb_release" "figlet")
    missingdeps=""
    missingdepsinstall=""

    OS=$(uname -s | tr A-Z a-z)
    case $OS in
    linux)
        source /etc/os-release
        if [ -z "$ID_LIKE" ];then
            OS_ID=$ID
        else
            OS_ID=$ID_LIKE
        fi
        case $OS_ID in
        *debian*|*ubuntu*|*mint*)
            missingdepsinstall="sudo apt install"
            ;;
        *fedora*|*rhel*|*centos*)
            missingdepsinstall="sudo dnf install"
            ;;
        *arch*)
            missingdepsinstall="yay -S"
            ;;
        *)
            echo -n "unsupported linux package manager"
            ;;
        esac
    ;;

    darwin)
        missingdepsinstall="brew install"
    ;;

    *)
        echo -n "unsupported OS"
        ;;
    esac

    for dep in "${deps[@]}"; do
        if ! type $(echo "$dep" | cut -d\| -f1) &> /dev/null; then
            missingdeps=$(echo "$missingdeps$(echo "$dep" | cut -d\| -f1), ")
            missingdepsinstall=$(echo "$missingdepsinstall $(echo "$dep" | cut -d\| -f2)")
        fi
    done
    if [ -n "$missingdeps" ]; then
        echo "[ERROR] Missing dependencies! ($(echo "$missingdeps" | xargs | sed 's/.$//'))"
        echo "        You can install them using this command:"
        echo "        ----------------------------------------"
        echo "        $missingdepsinstall"
        echo "        ----------------------------------------"
        exit 1
    fi
}

function create_motdsh {
    echo "Creating motd.sh script and add to profile ..."
    cat <<-EOF > /etc/motd.sh
#!/bin/bash
#
#    motd.sh - generate motd.sh
#
set -e
${MOTD_PATH}00-header
${MOTD_PATH}10-sysinfo
${MOTD_PATH}90-footer
EOF

    chmod +x /etc/motd.sh
    echo "/etc/motd.sh" >> /etc/profile
}

function create_issuesh {
    echo "Creating issue.sh script ..."

    cat <<-EOF > /etc/issue.sh
#!/bin/bash
#
#    issue.sh - generate issue.sh
#
set -e
${MOTD_PATH}00-header > /etc/issue
${MOTD_PATH}10-sysinfo >> /etc/issue
${MOTD_PATH}90-footer >> /etc/issue
EOF

    chmod +x /etc/issue.sh
}

function create_systemd_updater_service {
    echo "Changing selinux level from enforcing to permissive..."
    echo "This allow service to write to /etc/issue"
    sed -i -e "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config

    echo "Creating issue.sh service ..."

    cat <<-EOF > /etc/systemd/system/update-issue.service
[Unit]
Description=Update issue
After=network-online.target

[Service]
User=root
Group=root
Type=oneshot
RemainAfterExit=yes
ExecStart=/etc/issue.sh
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl restart update-issue.service
}

function create_issue_generator {
    echo "Creating issue generator ..."
    cat <<-EOF > /etc/network/if-up.d/update-issue
#!/bin/bash
#
#    update-issue - write info to /etc/issue at boot
#
set -e

HEADER=$(/etc/update-motd.d/00-header)
SYSINFO=$(/etc/update-motd.d/10-sysinfo)

echo "$HEADER\n\n$SYSINFO" > /etc/issue
EOF

    chmod +x /etc/network/if-up.d/update-issue
}

function etc_files {
    mkdir -p $MOTD_PATH
    #echo "Copying files to update-motd.d dir ..."
    cp ./update-motd.d/* $MOTD_PATH

    echo "Backup /etc/{motd,issue} files ..."
    mv /etc/motd /etc/motd.ORI
    mv /etc/issue /etc/issue.ORI

    case $OS_ID in
    *debian*|*ubuntu*|*mint*)
        create_issue_generator
        ;;
    *fedora*|*rhel*|*centos*)
        create_motdsh
        create_issuesh
        create_systemd_updater_service    
        ;;
    *arch*)
        ;;
    *)
        echo -n "unsupported linux"
        ;;
    esac
}

is_root
check_dependencies 
etc_files