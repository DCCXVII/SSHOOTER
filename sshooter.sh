#!/bin/bash

# ASCII Art Tag
cat << 'END_ASCII'
 _____ _____ _                 _            
/  ___/  ___| |               | |           
\ `--.\ `--.| |__   ___   ___ | |_ ___ _ __ 
 `--. \`--. \ '_ \ / _ \ / _ \| __/ _ \ '__|
/\__/ /\__/ / | | | (_) | (_) | ||  __/ |   
\____/\____/|_| |_|\___/ \___/ \__\___|_|  
END_ASCII

# Function to list available network interfaces
list_network_interfaces() {
    echo "Available network interfaces:"
    # List network interfaces excluding loopback and down interfaces
    ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | grep -v 'DOWN' | nl
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
    # List available Wi-Fi networks
    echo "Scanning for available Wi-Fi networks..."
    echo
    iwlist scan | grep 'ESSID\|Address' | awk '
    BEGIN { print "Num  SSID                             BSSID             Port Open  WPS" }
    /ESSID:/ { ssid = substr($0, index($0, ":") + 2); }
    /Address:/ { 
        bssid = $2; 
        num = NR / 2 + 1; 
        printf "%-5d %-30s %-20s %-10s %-10s\n", num, ssid, bssid, "N/A", "N/A"; 
    }'

    # List network interfaces and prompt user to choose one
    list_network_interfaces
    read -p "Choose a network interface number: " choice

    # Get the selected interface based on user choice
    local interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | grep -v 'DOWN' | sed -n "${choice}p")

    # Validate the selected interface
    if [ -z "$interface" ]; then
        echo "Invalid interface selected. Exiting."
        exit 1
    fi

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