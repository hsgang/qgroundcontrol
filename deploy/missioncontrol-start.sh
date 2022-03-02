#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"

# hack until icon issue with AppImage is resolved
mkdir -p ~/.icons && cp "${HERE}/missioncontrol.png" ~/.icons

"${HERE}/MissionControl" "$@"
