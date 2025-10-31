# 1) Repository klonen
git clone https://github.com/ThomasUgh/Benchmark-Script.git
cd Benchmark-Script

# 2) Skript anpassen (Webhook + Servername)
nano bytebench.sh
#   WEBHOOK_URL="https://discord.com/api/webhooks/DEIN_WEBHOOK_HIER"
#   SERVER_NAME="Mein VPS / Node-Name"

# 3) Ausführbar machen
chmod +x bytebench.sh

# 4) Starten
./bytebench.sh
