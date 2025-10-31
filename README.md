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
