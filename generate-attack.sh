#!/bin/bash

clear
echo "========================================================"
echo "   SIMULATION D'ATTAQUE BRUTE-FORCE (DIRECT KAFKA)"
echo "========================================================"
echo ""

# --- CONFIGURATION ---
CONTAINER_NAME="kafka"
TOPIC_NAME="syslogs"
ATTACKER_IP="185.220.101.42"  # IP Tor Exit Node
TARGET_USER="root"
COUNT=20  # Nombre de tentatives

echo "[*] Cible      : Container '$CONTAINER_NAME' -> Topic '$TOPIC_NAME'"
echo "[*] Scénario   : L'IP $ATTACKER_IP tente de forcer l'utilisateur '$TARGET_USER'"
echo "[*] Action     : Envoi de $COUNT logs en rafale..."
echo ""

# --- BOUCLE D'ATTAQUE ---
for ((i=1; i<=COUNT; i++)); do
    # 1. Création du faux log SSH (Format standard Syslog)
    current_date=$(date +"%b %d %H:%M:%S")
    port=$((RANDOM % 59000 + 1000))
    pid_ssh=$((RANDOM % 9000 + 1000))
    
    # Le format doit matcher votre Regex Spark : "Failed password" ... "for" ... "from"
    log_message="$current_date server-prod sshd[$pid_ssh]: Failed password for invalid user $TARGET_USER from $ATTACKER_IP port $port ssh2"
    
    # 2. Affichage visuel
    echo " [$i/$COUNT] Envoi : $log_message"
    
    # 3. Injection directe dans Kafka (via Docker)
    docker exec $CONTAINER_NAME bash -c "echo '$log_message' | kafka-console-producer --broker-list localhost:9092 --topic $TOPIC_NAME > /dev/null 2>&1"
    
    # Petite pause pour simuler une attaque humaine ou bot rapide
    sleep 0.2
done

# --- CONCLUSION ---
echo ""
echo "========================================================"
echo "   ATTAQUE TERMINEE ! VERIFICATIONS :"
echo "========================================================"
echo "1. Regardez votre fenêtre Spark : Vous devriez voir des Batchs traiter des données."
echo "2. Allez sur Kibana : http://localhost:5601"
echo "3. Discover > Sélectionnez la vue 'security_events'"
echo "   (Si pas encore créée : Stack Management > Data Views > Create > 'security_events')"
echo ""
read -p "Appuyez sur une touche pour continuer..."
