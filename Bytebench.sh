#!/bin/bash

# VPS Benchmark Tool by Thomas U.

export LC_ALL=C

DURATION=30
SINGLE_THREADS=1
MULTI_THREADS=$(nproc)
WEBHOOK_URL="WEBHOOK-URL"
SERVER_NAME="DEIN VPS NAME"
HOSTNAME=$(hostname)
DATE=$(TZ="Europe/Berlin" date '+%Y-%m-%d %H:%M:%S %Z%z')
OS_VERSION=$(lsb_release -d | cut -f2-)

# Fehlende Pakete automatisch installieren
REQUIRED=(sysbench curl bc lsb_release speedtest-cli jq)
for pkg in "${REQUIRED[@]}"; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    echo "📦 Installiere $pkg ..."
    apt update -qq >/dev/null && apt install -y -qq "$pkg" >/dev/null
  fi
done

# Hardware Infos
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
RAM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{printf "%.0f", $2 / 1024}')
RAM_TOTAL_FMT=$(printf "%'.f" "$RAM_TOTAL")
DISK_MODEL=$(lsblk -ndo MODEL | head -n1)
if [ -z "$DISK_MODEL" ]; then DISK_MODEL=$(lsblk -ndo NAME | head -n1); fi

# CPU Benchmark (GENAU wie gefordert)
echo -e "\n🧠 CPU Single-Core Test..."
CPU_SINGLE=$(sysbench cpu --threads=1 run | awk '/total number of events:/ {print $5}')
CPU_SINGLE_FMT=$(printf "%'.f" "$CPU_SINGLE")

echo -e "\n🧠 CPU Multi-Core Test ($MULTI_THREADS Threads)..."
CPU_MULTI=$(sysbench cpu --threads="$MULTI_THREADS" run | awk '/total number of events:/ {print $5}')
CPU_MULTI_FMT=$(printf "%'.f" "$CPU_MULTI")

# RAM Benchmark (Score = MiB/s * Sekunden)
echo -e "\n🧠 RAM-Test..."
RAM_MBPS=$(sysbench memory --threads=$SINGLE_THREADS --time=$DURATION run | awk '/MiB\/sec/ {print $1}')
RAM_SCORE=$(printf "%.0f" "$(echo "$RAM_MBPS * $DURATION" | bc)")
RAM_SCORE_FMT=$(printf "%'.f" "$RAM_SCORE")

# SSD Write Benchmark (nur prepare & cleanup – Speed aus prepare)
echo -e "\n💾 SSD Write-Test (prepare → Speed aus Output)..."
WRITE_OUTPUT=$(sysbench fileio --file-total-size=2G --file-test-mode=rndwr prepare 2>&1)
sysbench fileio --file-total-size=2G --file-test-mode=rndwr cleanup >/dev/null 2>&1
# Beispielzeile: "(485.03 MiB/sec)."
WRITE_MBPS=$(echo "$WRITE_OUTPUT" | sed -n 's/.*(\([0-9.]\+\) MiB\/sec).*/\1/p' | head -n1)
if [ -z "$WRITE_MBPS" ]; then WRITE_MBPS="0.00"; fi
WRITE_MBPS_FMT=$(printf "%.2f" "$WRITE_MBPS")

# SSD Read Benchmark (nur prepare & cleanup – Speed aus cleanup; Fallback auf run)
echo -e "\n💾 SSD Read-Test (cleanup → Speed aus Output)..."
sysbench fileio --file-total-size=2G --file-test-mode=rndrd prepare >/dev/null 2>&1
READ_OUTPUT=$(sysbench fileio --file-total-size=2G --file-test-mode=rndrd cleanup 2>&1)
READ_MBPS=$(echo "$READ_OUTPUT" | sed -n 's/.*(\([0-9.]\+\) MiB\/sec).*/\1/p' | head -n1)

# Fallback, falls cleanup keine MiB/s liefert (manche Builds tun das nicht)
if [ -z "$READ_MBPS" ]; then
  READ_MBPS=$(sysbench fileio --file-total-size=2G --file-test-mode=rndrd --time=$DURATION --threads=$SINGLE_THREADS run \
               | awk '/read, MiB\/s:/ {print $3}' | head -n1)
fi
if [ -z "$READ_MBPS" ]; then READ_MBPS="0.00"; fi
READ_MBPS_FMT=$(printf "%.2f" "$READ_MBPS")

# Speedtest
echo -e "\n🌐 Netzwerk-Speedtest..."
SPEED=$(speedtest-cli --secure --json)
PING=$(echo "$SPEED" | jq -r '.ping // 0')
DOWNLOAD=$(echo "$SPEED" | jq -r '.download // 0')
UPLOAD=$(echo "$SPEED" | jq -r '.upload // 0')
DL_MBPS=$(printf "%.2f" "$(echo "$DOWNLOAD / 1000000" | bc -l)")
UL_MBPS=$(printf "%.2f" "$(echo "$UPLOAD / 1000000" | bc -l)")

# Discord Webhook senden (grün)
curl -s -H "Content-Type: application/json" \
  -X POST -d @- "$WEBHOOK_URL" <<EOF
{
  "embeds": [{
    "title": "📊 VPS Benchmark abgeschlossen",
    "color": 65280,
    "fields": [
      { "name": "🖥️ Server", "value": "$SERVER_NAME", "inline": true },
      { "name": "📅 Datum",  "value": "$DATE", "inline": true },
      { "name": "💻 OS",     "value": "$OS_VERSION", "inline": true },

      { "name": "🧠 CPU", "value": "$CPU_MODEL", "inline": false },
      { "name": "💾 RAM", "value": "${RAM_TOTAL_FMT} MB", "inline": true },
      { "name": "📀 SSD", "value": "$DISK_MODEL", "inline": true },

      { "name": "🧠 CPU Single-Core", "value": "$CPU_SINGLE_FMT Punkte", "inline": true },
      { "name": "🧠 CPU Multi-Core ($MULTI_THREADS Threads)", "value": "$CPU_MULTI_FMT Punkte", "inline": true },
      { "name": "⚙️ RAM Score", "value": "$RAM_SCORE_FMT Punkte", "inline": true },

      { "name": "📤 Write Speed", "value": "$WRITE_MBPS_FMT MiB/s", "inline": true },
      { "name": "📥 Read  Speed", "value": "$READ_MBPS_FMT MiB/s", "inline": true },

      { "name": "🌐 Netzwerk", "value": "Ping: ${PING} ms\nDownload: ${DL_MBPS} Mbit/s\nUpload: ${UL_MBPS} Mbit/s", "inline": false }
    ],
    "footer": { "text": "$HOSTNAME" }
  }]
}
EOF

# Terminal-Ausgabe
echo -e "\n✅ Benchmark abgeschlossen für $SERVER_NAME ($HOSTNAME)"
echo "CPU Single-Core: $CPU_SINGLE_FMT Punkte"
echo "CPU Multi-Core ($MULTI_THREADS Threads): $CPU_MULTI_FMT Punkte"
echo "RAM Score: $RAM_SCORE_FMT Punkte"
echo "Write Speed: $WRITE_MBPS_FMT MiB/s"
echo "Read  Speed: $READ_MBPS_FMT MiB/s"
echo "Netzwerk: Ping ${PING} ms | Download ${DL_MBPS} Mbit/s | Upload ${UL_MBPS} Mbit/s"
echo "System: $CPU_MODEL | RAM: ${RAM_TOTAL_FMT} MB | SSD: $DISK_MODEL | OS: $OS_VERSION"
