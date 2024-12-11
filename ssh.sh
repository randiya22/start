#!/bin/bash
# Usage: wget https://raw.githubusercontent.com/katy-the-kat/realinstallscript/refs/heads/main/installer4space.sh && bash installer4space.sh
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi
touch /ports.txt
echo '#!/bin/bash
PORTS_FILE="/ports.txt"
add_port() {
    local local_port=$1
    if [[ -z "$local_port" ]]; then
        echo "Please provide a local port to forward."
        exit 1
    fi
    if [[ "$local_port" == "22" ]]; then
        echo "Port 22 cannot be added."
        exit 1
    fi
    if grep -q ":${local_port}$" "$PORTS_FILE"; then
        echo "Port ${local_port} is already forwarded."
        exit 1
    fi
    local random_port
    random_port=$(shuf -i 1-65535 -n 1)
    while [[ "$random_port" -eq 22 ]]; do
        random_port=$(shuf -i 1-65535 -n 1)
    done
    ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@104.219.236.245 -p 65535 > /dev/null &
    ssh_pid=$!
    echo "${random_port}:${local_port}" >> $PORTS_FILE
    echo "${local_port} is now on 104.219.236.245:${random_port}"
}
remove_port() {
    local local_port=$1
    if [[ -z "$local_port" ]]; then
        echo "Please provide a local port to remove."
        exit 1
    fi
    random_port=$(grep ":${local_port}$" $PORTS_FILE | cut -d':' -f1)
    if [[ -z "$random_port" ]]; then
        echo "Port ${local_port} not found."
        exit 1
    fi
    pkill -f "ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@104.219.236.245 -p 65535" > /dev/null
    sed -i "/${random_port}:${local_port}/d" $PORTS_FILE > /dev/null
    echo "Port ${local_port} has been removed."
}
refresh_ports() {
    if [[ ! -f "$PORTS_FILE" ]]; then
        echo "No ports to refresh."
        exit 1
    fi
    while IFS= read -r line; do
        random_port=$(echo $line | cut -d':' -f1)
        local_port=$(echo $line | cut -d':' -f2)
        ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@104.219.236.245 -p 65535 > /dev/null &
    done < $PORTS_FILE
    echo "Ports have been successfully restarted."
}
list_ports() {
    if [[ ! -f "$PORTS_FILE" ]]; then
        echo "No ports to list."
        exit 1
    fi
    echo "Current port mappings:"
    while IFS= read -r line; do
        random_port=$(echo $line | cut -d':' -f1)
        local_port=$(echo $line | cut -d':' -f2)
        echo "Local port ${local_port} -> Public port ${random_port} (104.219.236.245)"
    done < $PORTS_FILE
}
case "$1" in
    add)
        add_port "$2"
        ;;
    remove)
        remove_port "$2"
        ;;
    refresh)
        refresh_ports
        ;;
    list)
        list_ports
        ;;
    *)
        echo "Usage: $0 {add|remove|refresh|list} [port]"
        exit 1
        ;;
esac
' > /usr/bin/port
chmod +x /usr/bin/port
echo "Enabling PermitRootLogin in SSH configuration..."
sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
generate_password() {
    PASSWORD=$(tr -dc 'A-Za-z' </dev/urandom | head -c 30)
    echo $PASSWORD
}
PASSWORD=$(generate_password)
echo "root:$PASSWORD" | chpasswd
clear
echo Use this to SSH
echo '- SSH IP: ssh.is-a.space'
echo '- SSH Username: ssh'
echo '- Token: $EnterAToken'
echo 'is it legit (post a pic of noefetch and say legit)'
echo
echo For staff:
echo Please enter these into /generate_token
echo - IP: $(hostname -I)
echo - Password: $PASSWORD
echo /generate_token ip:$(hostname -I) password:$PASSWORD