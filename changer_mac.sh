#!/bin/bash

# Add colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Function to display network interfaces
display_interfaces() {
    echo -e "${CYAN}Available network interfaces:${RESET}"
    # Extract interface names from ifconfig output using awk and grep
    interfaces=$(ifconfig -a | grep -oP '^\w+')
    i=1
    declare -gA iface_map
    while IFS= read -r line; do
        echo -e "${GREEN}[$i] $line${RESET}"
        iface_map["$i"]="$line"
        i=$((i + 1))
    done <<< "$interfaces"
}

# Display interfaces initially
display_interfaces

# Ask the user to enter the interface number
while true; do
    read -p "$(echo -e "${YELLOW}Enter the number of the network interface you want to modify: ${RESET}")" iface_number
    # Validate the entered number
    if [[ -n "${iface_map["$iface_number"]}" ]]; then
        interface="${iface_map["$iface_number"]}"
        break
    else
        echo -e "${RED}Invalid selection. Please try again.${RESET}"
        display_interfaces # Re-display interfaces on invalid input
    fi
done

# Disable the selected network interface
echo -e "${BLUE}Disabling the network interface $interface...${RESET}"
ifconfig "$interface" down

# Ask the user if they want to assign a specific MAC address
while true; do
    read -p "$(echo -e "${YELLOW}Do you want to assign a specific MAC address? (yes/y or no/n): ${RESET}")" response
    if [[ "$response" =~ ^(yes|y)$ ]]; then
        # Ask for the new MAC address
        while true; do
            read -p "$(echo -e "${YELLOW}Enter the new MAC address (e.g., 00:11:22:33:44:55): ${RESET}")" mac_address
            # Validate the MAC address format
            if [[ "$mac_address" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                echo -e "${BLUE}Changing MAC address to $mac_address...${RESET}"
                macchanger -m "$mac_address" "$interface"
                break
            else
                echo -e "${RED}Invalid MAC address format. Please try again.${RESET}"
            fi
        done
        break
    elif [[ "$response" =~ ^(no|n)$ ]]; then
        # Change the MAC address to a random one
        echo -e "${BLUE}Changing MAC address to a random one...${RESET}"
        macchanger -a "$interface"
        break
    else
        echo -e "${RED}Invalid response. Please answer with yes/y or no/n.${RESET}"
    fi
done

# Enable the network interface
echo -e "${BLUE}Enabling the network interface $interface...${RESET}"
ifconfig "$interface" up

# Restart the network manager service
if command -v systemctl &> /dev/null; then
    echo -e "${BLUE}Restarting NetworkManager service...${RESET}"
    systemctl restart NetworkManager
else
    echo -e "${BLUE}Restarting network-manager service...${RESET}"
    service network-manager restart
fi

echo -e "${GREEN}MAC address changed successfully for $interface!${RESET}"