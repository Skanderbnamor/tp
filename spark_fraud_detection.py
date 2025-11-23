from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, TimestampType
import sys
import os

# =============================================================================
# 1. INITIALISATION DE LA SESSION SPARK
# =============================================================================
spark = SparkSession.builder \
    .appName("UnifiedThreatDefense") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")
print(">>> Démarrage du Moteur de Sécurité Unifié (SIEM) sous Linux...")

# =============================================================================
# 2. LECTURE MULTI-SOURCES (KAFKA)
# =============================================================================
df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", "172.25.0.21:9092") \
    .option("subscribe", "syslogs,fraud_alerts") \
    .option("startingOffsets", "latest") \
    .load()

input_stream = df.select(
    col("topic"),
    col("timestamp").alias("kafka_ts"),
    col("value").cast("string").alias("payload")
)

# =============================================================================
# 3. DÉFINITION DU SCHÉMA JSON (Carding)
# =============================================================================
carding_schema = StructType([
    StructField("transaction_id", StringType()),
    StructField("amount", DoubleType()),
    StructField("currency", StringType()),
    StructField("country", StringType()),
    StructField("city", StringType()),
    StructField("ip", StringType()),
    StructField("user", StringType()),
    StructField("status", StringType()),
    StructField("geoip", StructType([
        StructField("location", StringType())
    ]))
])

# =============================================================================
# 4. LOGIQUE DE TRAITEMENT HYBRIDE
# =============================================================================
syslog_logic = when(col("topic") == "syslogs", 
    when(col("payload").rlike(r"Failed password|authentication failure"), "SSH_BRUTE_FORCE")
    .when(col("payload").rlike(r"(?i)UNION\s+SELECT|' OR '1'='1|sleep\(\d+\)"), "SQL_INJECTION")
    .when(col("payload").rlike(r"(?i)<script>|javascript:|onerror="), "XSS_ATTACK")
    .when(col("payload").rlike(r"\.\./\.\./|/etc/passwd"), "PATH_TRAVERSAL")
    .when(col("payload").rlike(r"(?i)nmap|masscan|dirbuster"), "SCANNER_TOOL")
    .otherwise("NORMAL_TRAFFIC")
).otherwise(lit(None))

syslog_ip = regexp_extract(col("payload"), r"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})", 1)
parsed_json = from_json(col("payload"), carding_schema)

# =============================================================================
# 5. UNIFICATION ET ENRICHISSEMENT
# =============================================================================
processed = input_stream.withColumn("json_data", 
    when(col("topic") == "fraud_alerts", parsed_json).otherwise(lit(None))
)

final_df = processed.select(
    coalesce(col("kafka_ts"), current_timestamp()).alias("@timestamp"),
    coalesce(syslog_logic, when(col("topic") == "fraud_alerts", "CARDING_FRAUD")).alias("attack_type"),
    coalesce(col("json_data.ip"), syslog_ip).alias("source_ip"),
    coalesce(col("json_data.user"), lit("unknown")).alias("user"),
    # REMARQUE IMPORTANTE : L'enrichissement GeoIP par Kibana sera appliqué au champ "source_ip"
    struct(
        col("json_data.geoip.location").alias("location"),
        col("json_data.country").alias("country_name"),
        col("json_data.city").alias("city_name")
    ).alias("geoip"),
    struct(
        col("json_data.amount").alias("amount"),
        col("json_data.currency").alias("currency"),
        col("json_data.transaction_id").alias("id"),
        col("json_data.status").alias("status")
    ).alias("transaction"),
    col("payload").alias("raw_message")
)

alerts = final_df.filter(col("attack_type") != "NORMAL_TRAFFIC")

# =============================================================================
# 6. ÉCRITURE VERS ELASTICSEARCH
# =============================================================================
print(">>> Pipeline Unifié Actif. Écriture vers l'index 'security_events'...")

# Checkpoint critique pour la reprise sur erreur
query = alerts \
    .writeStream \
    .outputMode("append") \
    .format("es") \
    .option("es.nodes", "elasticsearch") \
    .option("es.port", "9200") \
    .option("es.resource", "security_events") \
    .option("es.ingest.pipeline", "geoip-enrichment") \
    .option("es.nodes.wan.only", "true") \
    .option("checkpointLocation", "/tmp/checkpoint_unified_security") \
    .start()

# Gestion propre de l'arrêt
try:
    query.awaitTermination()
except KeyboardInterrupt:
    print(">>> Arrêt demandé par l'utilisateur...")
    query.stop()
    spark.stop()
    print(">>> Session Spark arrêtée proprement.")
