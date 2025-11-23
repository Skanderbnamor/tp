#!/bin/bash

# start-all-containers.sh
echo "========================================================"
echo "   LANCEMENT COMPLET DES CONTENEURS FRAUD DETECTION"
echo "========================================================"

# Fonction pour vérifier si un service est prêt
wait_for_service() {
    local service=$1
    local host=$2
    local port=$3
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Attente de $service ($host:$port)..."
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z $host $port >/dev/null 2>&1; then
            echo "✅ $service est prêt"
            return 0
        fi
        echo "   Tentative $attempt/$max_attempts..."
        sleep 5
        ((attempt++))
    done
    
    echo "❌ $service n'est pas prêt après $max_attempts tentatives"
    return 1
}

# Arrêter tout d'abord pour un démarrage propre
echo "🧹 Nettoyage des conteneurs existants..."
docker-compose down

# 1. Démarrer Zookeeper
echo ""
echo "1. 🚀 Démarrage de Zookeeper..."
docker-compose up -d zookeeper
wait_for_service "Zookeeper" "localhost" "2181"

# 2. Démarrer Kafka
echo ""
echo "2. 🚀 Démarrage de Kafka..."
docker-compose up -d kafka

# Attendre Kafka avec vérification de commande
echo "⏳ Attente que Kafka soit opérationnel..."
for i in {1..30}; do
    if docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
        echo "✅ Kafka est opérationnel"
        break
    fi
    echo "   Tentative $i/30..."
    sleep 5
done

# Créer les topics Kafka
echo "📝 Création des topics Kafka..."
docker exec kafka kafka-topics --create --topic syslogs --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092 --if-not-exists || true
docker exec kafka kafka-topics --create --topic fraud_alerts --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092 --if-not-exists || true

# 3. Démarrer Elasticsearch
echo ""
echo "3. 🚀 Démarrage d'Elasticsearch..."
docker-compose up -d elasticsearch

# Attendre Elasticsearch
echo "⏳ Attente qu'Elasticsearch soit prêt..."
for i in {1..30}; do
    if curl -s http://localhost:9200 >/dev/null 2>&1; then
        echo "✅ Elasticsearch est opérationnel"
        break
    fi
    echo "   Tentative $i/30..."
    sleep 5
done

# 4. Démarrer Kibana
echo ""
echo "4. 🚀 Démarrage de Kibana..."
docker-compose up -d kibana
wait_for_service "Kibana" "localhost" "5601"

# 5. Démarrer Spark
echo ""
echo "5. 🚀 Démarrage de Spark Cluster..."
docker-compose up -d spark-master spark-worker
wait_for_service "Spark Master" "localhost" "8081"

# 6. Démarrer Syslog-ng
echo ""
echo "6. 🚀 Démarrage de Syslog-ng..."
docker-compose up -d syslog-ng
sleep 5

# Vérification finale
echo ""
echo "========================================================"
echo "           VÉRIFICATION FINALE DES CONTENEURS"
echo "========================================================"
docker-compose ps

echo ""
echo "📊 RÉSUMÉ DES PORTS :"
echo "   Kibana        : http://localhost:5601"
echo "   Spark Master  : http://localhost:8081"
echo "   Spark UI      : http://localhost:4040"
echo "   Elasticsearch : http://localhost:9200"

echo ""
echo "🎯 Pour lancer la détection de fraude : ./start-detection.sh"
echo "🎯 Pour générer des attaques de test : ./generate-attack.sh"
echo ""
echo "========================================================"
echo "            LANCEMENT TERMINÉ AVEC SUCCÈS!"
echo "========================================================"
