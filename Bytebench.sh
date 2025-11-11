#!/bin/bash

# VPS Benchmark Tool by Thomas U. (v2.0)

export LC_ALL=C

DURATION=30
SINGLE_THREADS=1
MULTI_THREADS=$(nproc)
WEBHOOK_URL="WEBHOOK-URL"
SERVER_NAME="DEIN VPS NAME"
HOSTNAME=$(hostname)
DATE=$(TZ="Europe/Berlin" date '+%Y-%m-%d %H:%M:%S')
OS_VERSION=$(lsb_release -d | cut -f2-)

# Fehlende Pakete automatisch installieren
REQUIRED=(sysbench curl bc lsb_release speedtest-cli jq fio)
echo "📦 Prüfe benötigte Pakete..."
for pkg in "${REQUIRED[@]}"; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    echo "   → Installiere $pkg ..."
    apt update -qq >/dev/null && apt install -y -qq "$pkg" >/dev/null
  fi
done

# Hardware Infos
CPU_MODEL=$(lscpu | grep "Model name" | sed 's/Model name:[ \t]*//')
RAM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{printf "%.0f", $2 / 1024}')
RAM_TOTAL_FMT=$(printf "%'.f" "$RAM_TOTAL")
DISK_MODEL=$(lsblk -ndo MODEL | head -n1)
if [ -z "$DISK_MODEL" ]; then DISK_MODEL=$(lsblk -ndo NAME | head -n1); fi

echo -e "\n╔═══════════════════════════════════════╗"
echo -e "║   VPS BENCHMARK - $SERVER_NAME"
echo -e "╚═══════════════════════════════════════╝\n"


echo -e "🧠 CPU Benchmarks\n"
echo "   → Single-Core Test..."
CPU_SINGLE=$(sysbench cpu --threads=1 run | awk '/total number of events:/ {print $5}')
CPU_SINGLE_FMT=$(printf "%'.f" "$CPU_SINGLE")

echo "   → Multi-Core Test ($MULTI_THREADS Threads)..."
CPU_MULTI=$(sysbench cpu --threads="$MULTI_THREADS" run | awk '/total number of events:/ {print $5}')
CPU_MULTI_FMT=$(printf "%'.f" "$CPU_MULTI")


echo -e "\n💾 RAM Benchmark\n"
echo "   → Memory Test läuft..."
RAM_OUTPUT=$(sysbench memory --threads=$MULTI_THREADS --time=$DURATION run)
RAM_MBPS=$(echo "$RAM_OUTPUT" | grep "MiB/sec" | sed 's/.*(\([0-9.]*\) MiB\/sec)/\1/')
RAM_OPS=$(echo "$RAM_OUTPUT" | awk '/total number of events:/ {print $5}')
RAM_MBPS_FMT=$(printf "%.2f" "$RAM_MBPS")
RAM_OPS_FMT=$(printf "%'.f" "$RAM_OPS")


echo -e "\n💽 Disk Benchmarks (FIO)\n"

# Write Test
echo "   → Write Test (Sequential)..."
FIO_WRITE=$(fio --name=write-test --size=1G --filename=/tmp/fio-testfile --bs=128k --rw=write --direct=1 --numjobs=1 --time_based --runtime=30 --group_reporting 2>&1)
WRITE_MBPS=$(echo "$FIO_WRITE" | grep "WRITE:" | awk '{print $2}' | sed 's/bw=\([0-9.]*\)MiB.*/\1/')
WRITE_IOPS=$(echo "$FIO_WRITE" | grep "WRITE:" | awk '{print $4}' | sed 's/iops=\([0-9]*\).*/\1/')
if [ -z "$WRITE_MBPS" ]; then WRITE_MBPS="0.00"; fi
if [ -z "$WRITE_IOPS" ]; then WRITE_IOPS="0"; fi
WRITE_MBPS_FMT=$(printf "%.2f" "$WRITE_MBPS")
WRITE_IOPS_FMT=$(printf "%'.f" "$WRITE_IOPS")

# Read Test
echo "   → Read Test (Sequential)..."
FIO_READ=$(fio --name=read-test --size=1G --filename=/tmp/fio-testfile --bs=128k --rw=read --direct=1 --numjobs=1 --time_based --runtime=30 --group_reporting 2>&1)
READ_MBPS=$(echo "$FIO_READ" | grep "READ:" | awk '{print $2}' | sed 's/bw=\([0-9.]*\)MiB.*/\1/')
READ_IOPS=$(echo "$FIO_READ" | grep "READ:" | awk '{print $4}' | sed 's/iops=\([0-9]*\).*/\1/')
if [ -z "$READ_MBPS" ]; then READ_MBPS="0.00"; fi
if [ -z "$READ_IOPS" ]; then READ_IOPS="0"; fi
READ_MBPS_FMT=$(printf "%.2f" "$READ_MBPS")
READ_IOPS_FMT=$(printf "%'.f" "$READ_IOPS")

# Random Read/Write Test (70% Read, 30% Write)
echo "   → Realistic Mixed Test (70% Read / 30% Write)..."
FIO_MIXED=$(fio --name=realistic-test --filename=/tmp/fio-testfile-mixed --size=2G --bs=64k --rw=randrw --rwmixread=70 --direct=1 --iodepth=16 --numjobs=4 --time_based --runtime=60 --group_reporting 2>&1)
MIXED_READ_MBPS=$(echo "$FIO_MIXED" | grep "READ:" | awk '{print $2}' | sed 's/bw=\([0-9.]*\)MiB.*/\1/')
MIXED_WRITE_MBPS=$(echo "$FIO_MIXED" | grep "WRITE:" | awk '{print $2}' | sed 's/bw=\([0-9.]*\)MiB.*/\1/')
MIXED_READ_IOPS=$(echo "$FIO_MIXED" | grep "READ:" | awk '{print $4}' | sed 's/iops=\([0-9]*\).*/\1/')
MIXED_WRITE_IOPS=$(echo "$FIO_MIXED" | grep "WRITE:" | awk '{print $4}' | sed 's/iops=\([0-9]*\).*/\1/')

if [ -z "$MIXED_READ_MBPS" ]; then MIXED_READ_MBPS="0.00"; fi
if [ -z "$MIXED_WRITE_MBPS" ]; then MIXED_WRITE_MBPS="0.00"; fi
if [ -z "$MIXED_READ_IOPS" ]; then MIXED_READ_IOPS="0"; fi
if [ -z "$MIXED_WRITE_IOPS" ]; then MIXED_WRITE_IOPS="0"; fi

MIXED_READ_MBPS_FMT=$(printf "%.2f" "$MIXED_READ_MBPS")
MIXED_WRITE_MBPS_FMT=$(printf "%.2f" "$MIXED_WRITE_MBPS")
MIXED_READ_IOPS_FMT=$(printf "%'.f" "$MIXED_READ_IOPS")
MIXED_WRITE_IOPS_FMT=$(printf "%'.f" "$MIXED_WRITE_IOPS")

# Testdaten aufräumen
echo "   → Räume Testdaten auf..."
rm -f /tmp/fio-testfile /tmp/fio-testfile-mixed


echo -e "\n🌐 Netzwerk Tests\n"

# Speedtest-CLI
echo "   → Speedtest-CLI..."
SPEEDTEST=$(speedtest-cli --secure --json)
PING_SPEEDTEST=$(echo "$SPEEDTEST" | jq -r '.ping // 0')
DOWNLOAD_SPEEDTEST=$(echo "$SPEEDTEST" | jq -r '.download // 0')
UPLOAD_SPEEDTEST=$(echo "$SPEEDTEST" | jq -r '.upload // 0')
DL_MBPS_SPEEDTEST=$(printf "%.2f" "$(echo "$DOWNLOAD_SPEEDTEST / 1000000" | bc -l)")
UL_MBPS_SPEEDTEST=$(printf "%.2f" "$(echo "$UPLOAD_SPEEDTEST / 1000000" | bc -l)")
SPEEDTEST_SERVER=$(echo "$SPEEDTEST" | jq -r '.server.sponsor // "Unknown"')
SPEEDTEST_LOCATION=$(echo "$SPEEDTEST" | jq -r '.server.name // "Unknown"')


echo -e "\n📤 Sende Ergebnisse an Discord...\n"

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

      { "name": "━━━━━━━━━ Hardware ━━━━━━━━━", "value": "** **", "inline": false },
      { "name": "🧠 CPU", "value": "$CPU_MODEL", "inline": false },
      { "name": "💾 RAM", "value": "${RAM_TOTAL_FMT} MB", "inline": true },
      { "name": "📀 SSD", "value": "$DISK_MODEL", "inline": true },

      { "name": "━━━━━━━━━ CPU Benchmarks ━━━━━━━━━", "value": "** **", "inline": false },
      { "name": "🧠 Single-Core", "value": "$CPU_SINGLE_FMT Punkte", "inline": true },
      { "name": "🧠 Multi-Core ($MULTI_THREADS Threads)", "value": "$CPU_MULTI_FMT Punkte", "inline": true },

      { "name": "━━━━━━━━━ RAM Benchmark ━━━━━━━━━", "value": "** **", "inline": false },
      { "name": "💾 Throughput", "value": "$RAM_MBPS_FMT MiB/s", "inline": true },
      { "name": "💾 Operations", "value": "$RAM_OPS_FMT Ops", "inline": true },

      { "name": "━━━━━━━━━ Disk Benchmarks (FIO) ━━━━━━━━━", "value": "** **", "inline": false },
      { "name": "📤 Sequential Write", "value": "$WRITE_MBPS_FMT MiB/s ($WRITE_IOPS_FMT IOPS)", "inline": true },
      { "name": "📥 Sequential Read", "value": "$READ_MBPS_FMT MiB/s ($READ_IOPS_FMT IOPS)", "inline": true },
      { "name": "🔀 Mixed (70R/30W)", "value": "Read: $MIXED_READ_MBPS_FMT MiB/s ($MIXED_READ_IOPS_FMT IOPS)\\nWrite: $MIXED_WRITE_MBPS_FMT MiB/s ($MIXED_WRITE_IOPS_FMT IOPS)", "inline": false },

      { "name": "━━━━━━━━━ Netzwerk Tests ━━━━━━━━━", "value": "** **", "inline": false },
      { "name": "🌐 Speedtest-CLI", "value": "**Server:** $SPEEDTEST_SERVER ($SPEEDTEST_LOCATION)\\n**Ping:** ${PING_SPEEDTEST} ms\\n**Download:** ${DL_MBPS_SPEEDTEST} Mbit/s\\n**Upload:** ${UL_MBPS_SPEEDTEST} Mbit/s", "inline": false }
    ],
    "footer": { "text": "🖥️ $HOSTNAME • Benchmark v2.0" },
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  }]
}
EOF


echo -e "✅ Benchmark abgeschlossen für $SERVER_NAME ($HOSTNAME)\n"
echo "╔═══════════════════════════════════════╗"
echo "║          BENCHMARK ERGEBNISSE         ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "🧠 CPU:"
echo "   Single-Core:     $CPU_SINGLE_FMT Punkte"
echo "   Multi-Core:      $CPU_MULTI_FMT Punkte ($MULTI_THREADS Threads)"
echo ""
echo "💾 RAM:"
echo "   Throughput:      $RAM_MBPS_FMT MiB/s"
echo "   Operations:      $RAM_OPS_FMT Ops"
echo ""
echo "💽 Disk (FIO):"
echo "   Seq. Write:      $WRITE_MBPS_FMT MiB/s ($WRITE_IOPS_FMT IOPS)"
echo "   Seq. Read:       $READ_MBPS_FMT MiB/s ($READ_IOPS_FMT IOPS)"
echo "   Mixed 70R/30W:"
echo "     → Read:        $MIXED_READ_MBPS_FMT MiB/s ($MIXED_READ_IOPS_FMT IOPS)"
echo "     → Write:       $MIXED_WRITE_MBPS_FMT MiB/s ($MIXED_WRITE_IOPS_FMT IOPS)"
echo ""
echo "🌐 Netzwerk:"
echo "   Speedtest-CLI:"
echo "     → Server:      $SPEEDTEST_SERVER ($SPEEDTEST_LOCATION)"
echo "     → Ping:        ${PING_SPEEDTEST} ms"
echo "     → Download:    ${DL_MBPS_SPEEDTEST} Mbit/s"
echo "     → Upload:      ${UL_MBPS_SPEEDTEST} Mbit/s"
echo ""
echo "💻 System:"
echo "   CPU:             $CPU_MODEL"
echo "   RAM:             ${RAM_TOTAL_FMT} MB"
echo "   SSD:             $DISK_MODEL"
echo "   OS:              $OS_VERSION"
echo ""
echo "╚═══════════════════════════════════════╝"
