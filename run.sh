#!/bin/bash
# Auto build+upload script for ESP-AIR (PlatformIO)
#
# Usage: ./run.sh [--env ENV] [--port PORT] [--baud BAUD] [--monitor] [--yes]
# -e|--env   : PlatformIO environment to build (default: first env in platformio.ini or nodemcuv2)
# -p|--port  : Use a specific serial port (default: auto-detect)
# -b|--baud  : Serial baud rate for monitor (default: 115200)
# -m|--monitor: Open serial monitor after upload
# -y|--yes   : Assume yes for selection when multiple devices are found
# -l|--list  : List detected PIO devices and exit

set -euo pipefail

PIOSHELL=""
if command -v pio >/dev/null 2>&1; then
	PIO=pio
elif command -v platformio >/dev/null 2>&1; then
	PIO=platformio
else
	echo "PlatformIO CLI (pio) not found — please install it."
	exit 1
fi

DEFAULT_ENV="nodemcuv2"
if [[ -f platformio.ini ]]; then
	found_env=$(awk -F'[][]' '/^\[env:/{print $2; exit}' platformio.ini || true)
	if [[ -n $found_env ]]; then
		DEFAULT_ENV=$found_env
	fi
fi

ENV=$DEFAULT_ENV
PORT=""
BAUD=115200
MONITOR=0
ASSUME_YES=0

usage() {
	sed -n '1,120p' "$0" | sed -n '3,20p'
}

if [[ $# -eq 0 ]]; then
	# no args — default behaviour: build, auto-detect and upload
	:
fi

while [[ $# -gt 0 ]]; do
	case $1 in
		-e|--env)
			ENV=$2; shift 2;;
		-p|--port)
			PORT=$2; shift 2;;
		-b|--baud)
			BAUD=$2; shift 2;;
		-m|--monitor)
			MONITOR=1; shift;;
		-y|--yes)
			ASSUME_YES=1; shift;;
		-l|--list)
			$PIO device list || true; exit 0;;
		-h|--help)
			usage; exit 0;;
		*)
			echo "Unknown argument: $1"; usage; exit 1;;
	esac
done

log() { echo "[run.sh] $*"; }

find_port() {
	if [[ -n $PORT ]]; then
		echo "$PORT"
		return 0
	fi

	# Prefer PlatformIO device list if available
	detected=()
	while IFS= read -r line; do
		# get first whitespace-separated token => path
		port=$(printf "%s" "$line" | awk '{print $1}')
		# prefer USB/ACM/by-id/cu devices and ignore ttyS* (system serial) to reduce noise
		if [[ $port == /dev/ttyUSB* || $port == /dev/ttyACM* || $port == /dev/serial/by-id/* || $port == /dev/cu.* ]]; then
			detected+=("$port")
		fi
	done < <($PIO device list 2>/dev/null || true)

	# fallback to scanning common /dev ports (prefer USB/ACM/serial-by-id)
	if [[ ${#detected[@]} -eq 0 ]]; then
		for f in /dev/serial/by-id/* /dev/ttyUSB* /dev/ttyACM*; do
			[[ -e $f ]] && detected+=("$f")
		done
	fi

	if [[ ${#detected[@]} -eq 0 ]]; then
		echo ""; return 1
	fi

	if [[ ${#detected[@]} -eq 1 ]] || [[ $ASSUME_YES -eq 1 ]]; then
		# array is 0-indexed; return first element
		echo "${detected[0]}"; return 0
	fi

	log "Multiple devices found:"
	for ((i=1; i<=${#detected[@]}; i++)); do
		# display 1-based list, but array index is i-1
		echo "  $i) ${detected[i-1]}"
	done
	echo -n "Select device index [1]: "
	read idx
	idx=${idx:-1}
	if ! [[ $idx -ge 1 && $idx -le ${#detected[@]} ]]; then
		echo "Invalid selection"; return 1
	fi
	echo "${detected[idx-1]}"
}

log "Using PlatformIO CLI: $PIO"
log "Using PIO env: $ENV"

if [[ -z $PORT ]]; then
	PORT=$(find_port) || true
fi

if [[ -z $PORT ]]; then
	echo "No device port found. Use --port to specify the device (e.g. /dev/ttyUSB0)."
	$PIO device list 2>/dev/null || true
	exit 1
fi

log "Found port: $PORT"

# Strip leading 'env:' if the caller passed either 'env:nodemcuv2' or 'nodemcuv2'
CANON_ENV=${ENV#env:}
log "Building (env: $CANON_ENV)..."
$PIO run -e "$CANON_ENV"

log "Uploading to $PORT..."
if [[ ! -r $PORT || ! -w $PORT ]]; then
	log "Warning: current user may not have permission to access $PORT"
	log "If upload fails with 'Permission denied', add your user to the 'dialout' group and re-login:"
	echo "  sudo usermod -a -G dialout \$USER && logout (or reboot)"
fi

if ! $PIO run -e "$CANON_ENV" -t upload --upload-port "$PORT"; then
	log "Upload failed. If the error mentions permission denied, follow the suggestion above; otherwise inspect the output above for details."
	exit 1
fi

if [[ $MONITOR -eq 1 ]]; then
	log "Opening serial monitor ($BAUD)..."
	# Use --port to explicitly set the serial device
	$PIO device monitor -e "$CANON_ENV" --port "$PORT" --baud "$BAUD"
fi

log "Done."
