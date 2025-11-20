# 🚀 VPS Benchmark Script - Bytebench

<div align="center">

![Version](https://img.shields.io/badge/version-2.1-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash](https://img.shields.io/badge/bash-5.0+-orange.svg)

**Professionelles VPS Benchmarking mit automatischer Discord-Integration**

[Features](#-features) • [Installation](#-installation) • [Benchmark-Werte](#-gemessene-werte) • [Changelog](#-changelog)

</div>

---

## 📊 Übersicht

Bytebench ist ein umfassendes Benchmark-Tool für VPS/Server, das automatisch Hardware- und Netzwerk-Performance misst und die Ergebnisse strukturiert an Discord sendet.

### 🎯 Highlights

```
✅ Automatische Paket-Installation
✅ CPU Single & Multi-Core Tests
✅ RAM Performance mit sysbench
✅ Professionelle Disk-Tests mit FIO (Write/Read/Mixed)
✅ IOPS-Messung für alle Storage-Tests
✅ Netzwerk-Speed via Speedtest-CLI
✅ Automatisches Cleanup aller Testdaten
✅ Discord Webhook Integration mit strukturiertem Embed
```

---

## 🎨 Features

### 🧠 **CPU Benchmarks**
- **Single-Core Performance**: Sysbench Events/Score
- **Multi-Core Performance**: Nutzt alle verfügbaren Threads
- Ideal für Vergleiche zwischen verschiedenen CPU-Modellen

### 💾 **RAM Benchmark**
- **Durchsatz**: Gemessen in MiB/s
- **Operations**: Anzahl der Memory Operations
- Multi-threaded Test für realistische Werte

### 💽 **Disk Benchmarks (FIO)**

| Test Type | Beschreibung | Messwerte |
|-----------|-------------|-----------|
| **Sequential Write** | 1GB, 128k Blocks, 30s | MiB/s + IOPS |
| **Sequential Read** | 1GB, 128k Blocks, 30s | MiB/s + IOPS |
| **Mixed 70/30** | 2GB, 64k Blocks, 60s | MiB/s + IOPS (Read/Write) |

- ✅ Direct I/O für realistische Werte
- ✅ Automatisches Cleanup nach Test
- ✅ IOPS-Messung für latency-sensitive Workloads

### 🌐 **Netzwerk Test**
- **Speedtest-CLI** mit Server-Info & Standort
- Ping, Download & Upload Geschwindigkeit
- Automatische Best-Server-Auswahl

---

## 📦 Installation

```bash
# 1) Repository klonen
git clone https://github.com/ThomasUgh/Benchmark-Script.git
cd Benchmark-Script

# 2) Skript anpassen (Webhook + Servername)
nano Bytebench.sh
#   WEBHOOK_URL="https://discord.com/api/webhooks/DEIN_WEBHOOK_HIER"
#   SERVER_NAME="Mein VPS / Node-Name"

# 3) Ausführbar machen
chmod +x Bytebench.sh

# 4) Starten
./Bytebench.sh
```

> **💡 Hinweis**: Das Script installiert automatisch alle benötigten Pakete (`sysbench`, `fio`, `speedtest-cli`, etc.)

---

## 📊 Gemessene Werte

<details>
<summary><b>🧠 CPU Performance</b></summary>

```
Single-Core:  Sysbench Events (höher = besser)
Multi-Core:   Sysbench Events mit allen Threads
```
</details>

<details>
<summary><b>💾 RAM Performance</b></summary>

```
Throughput:   MiB/s Durchsatz
Operations:   Anzahl der Memory Operations
```
</details>

<details>
<summary><b>💽 Disk Performance</b></summary>

```
Sequential Write:  MiB/s + IOPS
Sequential Read:   MiB/s + IOPS  
Mixed 70R/30W:     MiB/s + IOPS (getrennt für Read/Write)
```
</details>

<details>
<summary><b>🌐 Netzwerk Performance</b></summary>

```
Speedtest-CLI:
  → Server & Standort
  → Ping (ms)
  → Download (Mbit/s)
  → Upload (Mbit/s)
```
</details>

---

## 🛠️ Technische Details

### Systemanforderungen
- **OS**: Linux (Ubuntu/Debian bevorzugt)
- **Shell**: Bash 4.0+
- **Root**: Empfohlen für Paket-Installation

### Automatisch installierte Pakete
```bash
sysbench      # CPU & RAM Benchmarks
fio           # Disk I/O Tests
speedtest-cli # Netzwerk Speed Tests
curl          # Webhook Requests
bc            # Berechnungen
jq            # JSON Parsing
lsb_release   # OS Information
```

### Benchmark-Parameter

**FIO Tests:**
```bash
Write:  --size=1G --bs=128k --rw=write --direct=1 --runtime=30s
Read:   --size=1G --bs=128k --rw=read --direct=1 --runtime=30s
Mixed:  --size=2G --bs=64k --rw=randrw --rwmixread=70 --iodepth=16 --numjobs=4 --runtime=60s
```

**Sysbench Memory:**
```bash
--threads=$(nproc) --time=30s
```

---

## 📸 Discord Output

Das Script sendet ein strukturiertes Embed mit:

```
📊 VPS Benchmark abgeschlossen

━━━━━━━━━ Hardware ━━━━━━━━━
🧠 CPU: [Model]
💾 RAM: [Size] MB
📀 SSD: [Model]

━━━━━━━━━ CPU Benchmarks ━━━━━━━━━
🧠 Single-Core: [Score] Punkte
🧠 Multi-Core: [Score] Punkte

━━━━━━━━━ RAM Benchmark ━━━━━━━━━
💾 Throughput: [Speed] MiB/s
💾 Operations: [Ops] Ops

━━━━━━━━━ Disk Benchmarks (FIO) ━━━━━━━━━
📤 Sequential Write: [Speed] MiB/s ([IOPS] IOPS)
📥 Sequential Read: [Speed] MiB/s ([IOPS] IOPS)
🔀 Mixed (70R/30W): [Details]

━━━━━━━━━ Netzwerk Tests ━━━━━━━━━
🌐 Speedtest-CLI: [Details]
```

---

## 📝 Changelog

### 🎉 v2.0 (11.11.2025)
```diff
+ Netzwerk-Test mit Speedtest-CLI (Server-Info + Standort)
+ RAM-Test auf sysbench memory umgestellt
+ Disk-Tests komplett auf FIO umgestellt
+ IOPS-Messung für alle Disk-Tests
+ Realistic Mixed Test (70R/30W) hinzugefügt
+ Automatisches Cleanup aller Testdaten
+ Verbessertes Discord Embed Layout
+ Bessere Terminal-Ausgabe mit ASCII-Boxen
+ Zeitformat ohne Timezone (nur HH:MM:SS)
+ Korrigierte RAM-Speed Berechnung
```

### 📦 v1.0
- Initiale Version mit grundlegenden Benchmarks

---

## 🤝 Contributing

Contributions sind willkommen! Öffne gerne Issues oder Pull Requests.

## 📄 Lizenz

MIT License - Thomas U.

---

<div align="center">

**Made with ❤️ by Thomas U.**

</div>
