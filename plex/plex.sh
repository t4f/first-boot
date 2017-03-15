#!/bin/bash

# Propt user for required variables
if [ ! -n "$plexuser" ]
    read -e -p "UID: " uid
    read -e -p "Plex User: " plexuser 
    read -e -p "Plex Password: " plexpassword
fi

uuid=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Get plex login token
plextoken=$(curl -sS -H "Content-Length: 0" -H "X-Plex-Client-Identifier: $uuid" --user "$plexuser:$plexpassword" -X POST https://my.plexapp.com/users/sign_in.xml | tail -n 2 | head -n 1  | cut -c25-44)

echo "<Preferences MachineIdentifier=\"$uuid\" agentAutoEnabled.com.plexapp.agents.lastfm.Artists.com.plexapp.agents.vevo=\"1\" MetricsEpoch=\"1\" AcceptedEULA=\"1\"  PlexOnlineToken=\"$token\" ManualPortMappingMode=\"1\" ManualPortMappingPort=\"$port\"/>" > /tmp/Preferences.xml

# Standard debian setup
bash ../debian/debian.sh

# Install plex/plexpy/plexremotetranscoder
docker pull linuxserver/plex
docker pull linuxserver/plexpy

docker create --name plex-$uid linuxserver/plex





