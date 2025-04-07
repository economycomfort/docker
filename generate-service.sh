#!/bin/bash
# This script generates avahi service files for Homebridge bridges and child bridges.
# It extracts the necessary information from the Homebridge configuration.
#
# Usage: ./generate-service.sh
# Make sure to run this script with sudo or as root, as it modifies system files.
# 
# Originally by David Hutchinson:
# https://www.devwithimagination.com/2020/02/02/running-homebridge-on-docker-without-host-network-mode/
#
# Modified to iterate over child bridges.
#
set -euo pipefail
IFS=$'\n\t'

function create_service_file {

  local name=$1
  local accessory_category=$2
  local mac_address=$3
  local port=$4
  local setup_id=$5

  # Write the service configuration file to the current directory
  cat <<EOF > "${name}.service"
<service-group>
  <name>$name</name>
  <service>
    <type>_hap._tcp</type>
    <port>$port</port>

    <!-- friendly name -->
    <txt-record>md=$name</txt-record>

    <!-- HAP version -->
    <txt-record>pv=1.0</txt-record>
    <!-- MAC -->
    <txt-record>id=${mac_address}</txt-record>
    <!-- Current configuration number -->
    <txt-record>c#=2</txt-record>

    <!-- accessory category -->
    <txt-record>ci=${accessory_category}</txt-record>

    <!-- accessory state -->
    <txt-record>s#=1</txt-record>
    <!-- Pairing Feature Flags -->
    <txt-record>ff=0</txt-record>
    <!-- Status flags -->
    <txt-record>sf=1</txt-record>
    <!-- setup hash -->
    <txt-record>sh=$(echo -n ${setup_id}${mac_address} | openssl dgst -binary -sha512 | head -c 4 | base64)</txt-record>
  </service>
</service-group>
EOF

  # Helper Message
  echo "Please ensure you have exposed port $port in docker-compose.yaml!"
}

# Find the running homebridge container
CONTAINER=$(sudo docker ps | grep homebridge | awk '{print $1}')

if [ -z "$CONTAINER" ]; then
  echo "No running homebridge container found"
  exit 1
fi

# Get configuration values out of the container configuration file
CONFIG=$(sudo docker exec "$CONTAINER" cat /homebridge/config.json)
NAME=$(echo "$CONFIG" | jq -r .bridge.name)
MAC=$(echo "$CONFIG" | jq -r .bridge.username)
PORT=$(echo "$CONFIG" | jq -r .bridge.port)

ACCESSORY_CONFIG=$(sudo docker exec "$CONTAINER" cat /homebridge/persist/AccessoryInfo.${MAC//:/}.json)
SETUPID=$(echo "$ACCESSORY_CONFIG" | jq -r .setupID)
CATEGORY=$(echo "$ACCESSORY_CONFIG" | jq -r .category)

# Create service file for primary bridge
create_service_file "$NAME" "$CATEGORY" "$MAC" "$PORT" "$SETUPID"

# Extract child bridges from config.json and create service files for them
echo "$CONFIG" | jq -c '.platforms[] | select(._bridge) | ._bridge' | while read -r bridge; do
  NAME=$(echo "$bridge" | jq -r .name)
  MAC=$(echo "$bridge" | jq -r .username)
  PORT=$(echo "$bridge" | jq -r .port)

  # Get accessory info for the child bridge
  ACCESSORY_CONFIG=$(sudo docker exec "$CONTAINER" cat /homebridge/persist/AccessoryInfo.${MAC//:/}.json)
  SETUPID=$(echo "$ACCESSORY_CONFIG" | jq -r .setupID)
  CATEGORY=$(echo "$ACCESSORY_CONFIG" | jq -r .category)

  create_service_file "$NAME" "$CATEGORY" "$MAC" "$PORT" "$SETUPID"
done

  # Move the generated service files to the avahi services directory
  echo "Moving generated service files to /etc/avahi/services/"
  for i in *.service; do
    sudo mv -i "$i" "/etc/avahi/services/${i// /}"
  done
  
  # Restart the avahi daemon to apply changes
  echo "Restarting avahi-daemon..."
  sudo systemctl restart avahi-daemon