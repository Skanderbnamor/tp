#!/bin/bash

clear
echo "========================================================"
echo "    SIMULATION D'ATTAQUES WEB (SQLi, XSS, TRAVERSAL)"
echo "========================================================"

CONTAINER_NAME="kafka"
TOPIC_NAME="syslogs"

# Liste de faux logs web malveillants (Format Apache/Nginx simulé)
declare -a ATTACKS=(
    "SQL Injection|192.168.1.50 - - [21/Nov/2025:10:00:01 +0000] \"GET /products.php?id=1 UNION SELECT 1,username,password FROM users\" 200 452"
    "SQL Injection|10.0.0.14 - - [21/Nov/2025:10:05:00 +0000] \"POST /login\" \"user=admin&pass=' OR '1'='1\" 500 124"
    "XSS Attack|45.33.22.11 - - [21/Nov/2025:11:20:00 +0000] \"GET /search?q=<script>alert(1)</script>\" 200 1500"
    "Path Traversal|185.200.10.5 - - [21/Nov/2025:12:00:00 +0000] \"GET /download?file=../../../../etc/passwd\" 403 0"
    "Scanner Tool|192.168.1.99 - - [21/Nov/2025:12:01:00 +0000] \"HEAD /admin.php\" 404 0 \"Nmap Scripting Engine\""
)

echo "[*] Injection des attaques dans Kafka..."

for attack in "${ATTACKS[@]}"; do
    IFS='|' read -r attack_type attack_msg <<< "$attack"
    
    echo " [!] Envoi ($attack_type) : $attack_msg"
    
    # Injection dans Kafka via docker
    docker exec $CONTAINER_NAME bash -c "echo '$attack_msg' | kafka-console-producer --broker-list localhost:9092 --topic $TOPIC_NAME > /dev/null 2>&1"
    
    sleep 0.5
done

echo ""
echo "Terminé. Vérifiez Kibana index 'security_events' !"
