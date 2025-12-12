# Copilot instructions — ESP-AIR (ESP8266 DHT11 + OLED)

Goal: help an AI coding agent be productive quickly by describing the repo architecture, recurring workflows, and concrete examples for common edits.

## Big picture
- Single microcontroller firmware project using PlatformIO (env: `nodemcuv2`) and the Arduino framework targeting ESP8266 (see `platformio.ini`).
- Intended features (from `README.md`): read a DHT11 sensor and render readings on a small OLED display. Typical components:
  - sensor code (DHT11), display code (OLED), and glue code in `src/` (main firmware loop).
  - hardware config constants should live in headers under `include/`.

## Where to look (quick references)
- `platformio.ini` — target board, platform, frameworks and build env(s).
- `src/main.cpp` — current program skeleton (contains `setup()` and `loop()` and a simple `myFunction` example).
- `include/` — project headers (hardware pin definitions, small helper APIs).
- `lib/` — private libraries; add self-contained libraries here (one directory per library).
- `README.md` — hardware wiring and intent (DHT11 on D1/GPIO5, etc.).

## Build / Upload / Debug workflows (concrete commands)
- Build: `pio run -e nodemcuv2`
- Upload to device: `pio run -e nodemcuv2 -t upload`
- Serial monitor: `pio device monitor -e nodemcuv2 --baud 115200` (adjust baud if needed)
- Clean: `pio run -e nodemcuv2 -t clean`
- Run unit tests (if you add a `native` or `unity` test env): `pio test --environment <env>`

Notes:
- Use VS Code + PlatformIO extension for faster iterative upload/debug if available.
- ESP8266 has limited hardware debug support; prefer `Serial` logging for inspection.

## Library & dependency conventions
- Prefer PlatformIO `lib_deps` in `platformio.ini` for third-party libs, or place small project-specific code under `lib/<name>/src` with an optional `library.json`.
- Example to add DHT/OLED libs to `platformio.ini`:
  ```ini
  lib_deps =
    adafruit/DHT sensor library@^1
    adafruit/SSD1306@^2
  ```
- Keep hardware pin definitions in `include/config.h` and reference them from `src/` and `lib/`.

## Coding patterns & project-specific expectations
- Use Arduino idioms: `setup()` initializes peripherals; `loop()` runs periodically. Keep `loop()` short and non-blocking.
- Place reusable code in `lib/` or `include/` (examples: `lib/dht11` or `include/dht.h`).
- Use `Serial.printf` / `Serial.println` for observability; follow existing simple style in `src/main.cpp`.
- Small helper functions should be defined under `src/` or `lib/<module>/src` and have clear, tested boundaries.

## Tests
- There's no test scaffolding yet; follow PlatformIO Test Runner with Unity if you add tests.
- Prefer adding a `native` environment for unit tests that run on the host (easier than MCU tests).

## PR / Change guidance for AI agents
- Keep changes small and focused; add tests (native) when changing logic that can be exercised off-device.
- Update `README.md` if you change wiring, pin assignments or behaviour visible to users.
- Mention the target `env` (usually `nodemcuv2`) in the PR description.

## Concrete example edits (use these patterns)
- Add DHT11 reading in `src/main.cpp`:
  - Add `#include "dht.h"` or `#include <DHT.h>` (via `lib_deps`).
  - Initialize sensor in `setup()` and call `readHumidity()` / `readTemperature()` in `loop()`.
  - Print readings with `Serial` and send to OLED draw functions.
- Create a small library `lib/dht11/src/dht11.cpp` and header `lib/dht11/src/dht11.h` for sensor encapsulation.

---
If anything above is incomplete or you want the instructions to emphasize other concerns (e.g., CI, OTA updates, power profiling), tell me which areas to expand and I'll iterate.