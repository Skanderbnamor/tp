🚨 Unified Threat Defense - Système de Détection de Fraude en Temps Réel
https://img.shields.io/badge/version-1.0.0-blue.svg
https://img.shields.io/badge/docker-%253E%253D20.0-green.svg
https://img.shields.io/badge/Apache%2520Spark-3.4.3-orange.svg

📋 Table des Matières
Aperçu

Architecture

Prérequis

Installation

Utilisation

Structure du Projet

API et Endpoints

Monitoring

Dépannage

Contribuer

Licence

🎯 Aperçu
Unified Threat Defense est une plateforme complète de détection de menaces en temps réel qui combine l'analyse de logs systèmes et la détection de fraude financière. Le système utilise Apache Spark Streaming pour traiter les données en temps réel depuis Kafka et les stocker dans Elasticsearch pour visualisation dans Kibana.

✨ Fonctionnalités Principales
🔍 Détection multi-menaces : SQL Injection, XSS, Brute Force SSH, Path Traversal

💳 Détection de fraude carding avec géolocalisation

📊 Visualisation temps réel avec Kibana et cartes géographiques

⚡ Traitement streaming avec Spark Structured Streaming

🐳 Conteneurisation complète avec Docker

🔔 Alertes automatiques et corrélation d'événements

🏗️ Architecture


Composants
Kafka : Bus de messages pour l'ingestion des logs

Spark Streaming : Traitement temps réel des données

Elasticsearch : Stockage et indexation des alertes

Kibana : Visualisation et tableaux de bord

Syslog-ng : Collecte et parsing des logs systèmes

Zookeeper : Coordination des services Kafka

📦 Prérequis
Système
Docker 20.0+

Docker Compose 2.0+

8GB RAM minimum

20GB espace disque libre

Réseau
Ports disponibles : 5601, 9200, 9092, 8081, 4040, 2181

🚀 Installation Rapide
1. Cloner le Repository
bash
git clone https://github.com/Skanderbnamor/tp.git
cd tp
2. Démarrer l'Infrastructure
bash
# Lancer tous les conteneurs
./start-all-containers.sh

# Ou manuellement
docker-compose up -d
3. Vérifier les Services
bash
# Vérifier l'état des conteneurs
docker-compose ps

# Vérifier les logs
docker-compose logs --follow
🎮 Utilisation
Démarrer la Détection
bash
# Lancer le job Spark Streaming
./start-detection.sh
Simuler des Attaques
bash
# Attaque brute force SSH
./generate-attack.sh

# Attaques web (SQLi, XSS, etc.)
./generate-web-attacks.sh

# Fraude carding mondiale
./generate-carding-attack.sh
Accéder aux Interfaces
Service	URL	Description
Kibana	http://localhost:5601	Tableaux de bord et visualisation
Spark UI	http://localhost:4040	Monitoring des jobs Spark
Spark Master	http://localhost:8081	Interface cluster Spark
Elasticsearch	http://localhost:9200	API de recherche
📁 Structure du Projet
text
tp/
├── 📊 docker-compose.yml          # Orchestration des conteneurs
├── 🔧 syslog-ng.conf              # Configuration Syslog-ng
├── ⚡ spark_fraud_detection.py    # Job Spark principal
├── 🚀 start-all-containers.sh    # Script de démarrage complet
├── 🔍 start-detection.sh         # Lancement de la détection
├── 🎯 generate-attack.sh         # Simulation brute force
├── 🌐 generate-web-attacks.sh    # Simulation attaques web
└── 💳 generate-carding-attack.sh # Simulation fraude carding
📊 Configuration Kibana
1. Créer l'Index Pattern
Allez sur http://localhost:5601

Stack Management → Index Patterns

Créer le pattern : security_events

Sélectionner @timestamp comme champ temporel

2. Importer les Dashboards
Exemple de visualisations à créer :

Carte des attaques géolocalisées

Graphique des types d'attaques

Timeline des événements

Top 10 des IPs attaquantes

🔧 API Elasticsearch
Rechercher les Alertes Récentes
bash
curl -X GET "http://localhost:9200/security_events/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-1h"
      }
    }
  },
  "sort": [{ "@timestamp": "desc" }]
}'
Statistiques des Attaques
bash
curl -X GET "http://localhost:9200/security_events/_search" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "attacks_by_type": {
      "terms": {
        "field": "attack_type.keyword"
      }
    }
  }
}'
📈 Monitoring
Vérifier la Santé des Services
bash
# Script de santé inclus
./health-check.sh

# Vérifier manuellement
docker-compose ps
curl http://localhost:9200/_cluster/health
Métriques Clés
Débit Kafka : Messages/segond traités

Latence Spark : Temps de traitement

Taux de Détection : Alertes générées

Couverture Géographique : Pays touchés

🐛 Dépannage
Problèmes Courants
❌ Les conteneurs ne démarrent pas

bash
# Vérifier les ports
sudo netstat -tulpn | grep -E ':(5601|9200|9092)'

# Nettoyer et redémarrer
docker-compose down
docker system prune -f
./start-all-containers.sh
❌ Spark ne trouve pas les dépendances

bash
# Forcer le téléchargement des JARs
docker exec -u 0 spark-master bash -c "mkdir -p /home/spark/.ivy2 && chown -R spark:spark /home/spark/.ivy2"
❌ Kafka non accessible

bash
# Vérifier les topics
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Recréer les topics
docker exec kafka kafka-topics --create --topic syslogs --partitions 1 --replication-factor 1 --bootstrap-server localhost:9092
Logs et Debugging
bash
# Voir tous les logs
docker-compose logs --follow

# Logs spécifiques à un service
docker-compose logs spark-master
docker-compose logs kafka

# Vérifier les erreurs Spark
docker exec spark-master tail -f /opt/spark/logs/spark--org.apache.spark.deploy.master.Master-*.out
🤝 Contribuer
Développement
Fork le projet

Créer une branche feature (git checkout -b feature/AmazingFeature)

Commit les changements (git commit -m 'Add some AmazingFeature')

Push sur la branche (git push origin feature/AmazingFeature)

Ouvrir une Pull Request

Tests
bash
# Lancer toutes les simulations
./generate-attack.sh
./generate-web-attacks.sh
./generate-carding-attack.sh

# Vérifier les données dans Kibana
📄 Licence
Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

👥 Auteurs
Skander Ben Amor - Développement initial

🙏 Remerciements
Apache Spark pour le moteur de streaming

Elastic pour la stack ELK

Confluent pour les images Kafka

Docker pour la conteneurisation
