#!/bin/bash

clear
echo "==================================================================="
echo "   SIMULATION D'ATTAQUE CARDING MONDIALE (DATA GEO-DISPERSÉE)"
echo "==================================================================="
echo ""

# --- CONFIGURATION ---
CONTAINER_NAME="kafka"
TOPIC_NAME="fraud_alerts"
COUNT=500

# Tableau associatif des pays avec coordonnées
declare -A TARGETS=(
    ["Nigeria"]="9.0820,8.6753:Lagos,Abuja,Kano"
    ["Brazil"]="-14.2350,-51.9253:São Paulo,Rio de Janeiro,Brasília"
    ["Colombia"]="4.5709,-74.2973:Bogotá,Medellín,Cali"
    ["Peru"]="-9.1900,-75.0152:Lima,Cusco,Arequipa"
    ["South Africa"]="-30.5595,22.9375:Johannesburg,Cape Town,Durban"
    ["Morocco"]="31.7911,-7.0926:Casablanca,Rabat,Marrakech"
    ["Indonesia"]="-0.7893,113.9213:Jakarta,Surabaya,Bali"
    ["Philippines"]="12.8797,121.7740:Manila,Cebu City,Davao"
    ["Russia"]="61.5240,105.3188:Moscow,Saint Petersburg,Novosibirsk"
    ["China"]="35.8617,104.1954:Beijing,Shanghai,Shenzhen"
)

echo "[*] Injection de $COUNT transactions frauduleuses dans Kafka..."
echo "[*] Cible : Topic '$TOPIC_NAME' via Container '$CONTAINER_NAME'"
echo ""

# Récupérer les clés du tableau associatif
countries=("${!TARGETS[@]}")

for ((i=1; i<=COUNT; i++)); do
    # 1. Sélection aléatoire d'un pays cible
    country_name=${countries[$RANDOM % ${#countries[@]}]}
    target_data=${TARGETS[$country_name]}
    
    # Extraire latitude, longitude et villes
    IFS=':' read -r coords cities_str <<< "$target_data"
    IFS=',' read -r base_lat base_lon <<< "$coords"
    IFS=',' read -ra cities <<< "$cities_str"
    
    # 2. "Jitter" Géographique (Dispersion)
    lat_jitter=$(echo "scale=4; ($RANDOM % 400 - 200) / 100.0" | bc)
    lon_jitter=$(echo "scale=4; ($RANDOM % 400 - 200) / 100.0" | bc)
    
    random_lat=$(echo "scale=4; $base_lat + $lat_jitter" | bc)
    random_lon=$(echo "scale=4; $base_lon + $lon_jitter" | bc)
    
    city=${cities[$RANDOM % ${#cities[@]}]}
    
    # 3. Construction du Log JSON
    amount=$((RANDOM % 4950 + 50))
    transaction_id="txn_$((RANDOM % 9000000 + 1000000))"
    ip="$((RANDOM % 255 + 1)).$((RANDOM % 255 + 1)).$((RANDOM % 255 + 1)).$((RANDOM % 255 + 1))"
    user="fraud_bot_$((RANDOM % 99 + 1))"
    attempts=$((RANDOM % 20 + 5))
    
    log_data=$(cat << EOF
{
    "@timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
    "transaction_id": "$transaction_id",
    "amount": $amount,
    "currency": "USD",
    "country": "$country_name",
    "city": "$city",
    "ip": "$ip",
    "user": "$user",
    "attempts": $attempts,
    "card_type": "Visa Platinum",
    "status": "DECLINED",
    "fraud_score": 0.99,
    "geoip": {
        "location": "$random_lat,$random_lon"
    }
}
EOF
    )
    
    # 4. Envoi via Docker (kafka-console-producer)
    echo "$log_data" | docker exec -i $CONTAINER_NAME kafka-console-producer --broker-list localhost:9092 --topic $TOPIC_NAME > /dev/null 2>&1
    
    # 5. Feedback Visuel
    echo " [$i/$COUNT] ALERTE $country_name ($city) :: ${amount}$ :: Geo[$random_lat, $random_lon]"
    
    # Pause variable pour simuler un trafic "humain/bot" rapide
    sleep_duration=$(echo "scale=3; ($RANDOM % 90 + 10) / 1000" | bc)
    sleep $sleep_duration
done

echo ""
echo "==================================================================="
echo "   ATTAQUE TERMINÉE - VÉRIFIEZ LA CARTE KIBANA !"
echo "==================================================================="
