#!/bin/sh

SERVICE=${SERVICE:=none}

gluetun_port_endpoint="http://localhost:8000/v1/openvpn/portforwarded"
transmission_config="/config/settings.json"
nicotine_config="/config/config"

#!/bin/bash

check_config_exists() {
  if [ ! -f "$1" ]; then
    echo "File not found: $1"
    exit 0
  fi
}

update_nicotine_config() {
  check_config_exists "$1"
  sed -E -i "s/portrange = \([0-9]+, [0-9]+\)/portrange = ($2, $2)/" "$1"
}

update_transmission_config() {
  check_config_exists "$1"
  jq --argjson new_port "$2" '.["peer-port"] = $new_port' "$1" > temp.json && mv temp.json "$1"
}

while true; do
  echo "Waiting for gluetun to intialize connection..."
  response=$(curl -s -w "%{http_code}" "$gluetun_port_endpoint")
  http_code=$(echo "$response" | tail -c 4)
  response_body=$(echo "$response" | head -c -4)

  if [ "$http_code" -eq 200 ]; then
    port="$(echo "$response_body" | jq -r '.port')"
    if [ ! "$port" -eq 0 ]; then
        echo "Forwarded port: $port"
        if [ "$SERVICE" = "nicotine+" ]; then
          update_nicotine_config "$nicotine_config" "$port"
        elif [ "$SERVICE" = "transmission" ]; then
          update_transmission_config "$transmission_config" "$port"
        else
          echo "Service $SERVICE not supported"
          break
        fi
        echo "Wrote port $port to $SERVICE config"
        break
    fi
  fi
  sleep 3
done
