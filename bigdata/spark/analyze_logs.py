import argparse
from datetime import datetime

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Analyze worker logs stored in Cassandra and write parquet outputs."
    )
    parser.add_argument("--cassandra-host", default="fingerprint-cassandra")
    parser.add_argument("--cassandra-port", default="9042")
    parser.add_argument("--keyspace", default="fingerprint_logs")
    parser.add_argument("--table", default="worker_event_logs_by_day")
    parser.add_argument("--output", default="/opt/spark-outputs")
    parser.add_argument("--day", help="Run batch for one day (YYYY-MM-DD)")
    parser.add_argument("--from", dest="from_time", help="Start timestamp (YYYY-MM-DDTHH:MM:SS)")
    parser.add_argument("--to", dest="to_time", help="End timestamp (YYYY-MM-DDTHH:MM:SS)")
    parser.add_argument("--top-workers", type=int, default=5)
    args = parser.parse_args()

    if args.day and (args.from_time or args.to_time):
        parser.error("Use either --day or --from/--to, not both.")
    if bool(args.from_time) ^ bool(args.to_time):
        parser.error("--from and --to must be provided together.")
    if not args.day and not (args.from_time and args.to_time):
        parser.error("Provide either --day or --from/--to.")

    return args


def build_range_label(args: argparse.Namespace) -> str:
    if args.day:
        return f"day={args.day}"
    safe_from = args.from_time.replace(":", "-")
    safe_to = args.to_time.replace(":", "-")
    return f"from={safe_from}_to={safe_to}"


def main() -> None:
    args = parse_args()

    spark = (
        SparkSession.builder.appName("fingerprint-log-analysis")
        .config("spark.cassandra.connection.host", args.cassandra_host)
        .config("spark.cassandra.connection.port", args.cassandra_port)
        .getOrCreate()
    )

    base_df = (
        spark.read.format("org.apache.spark.sql.cassandra")
        .options(table=args.table, keyspace=args.keyspace)
        .load()
        .withColumn("event_time", F.to_timestamp("event_time"))
    )

    if args.day:
        event_day = datetime.strptime(args.day, "%Y-%m-%d").date()
        filtered_df = base_df.where(F.col("event_day") == F.lit(event_day))
    else:
        filtered_df = base_df.where(
            (F.col("event_time") >= F.to_timestamp(F.lit(args.from_time)))
            & (F.col("event_time") < F.to_timestamp(F.lit(args.to_time)))
        )

    if filtered_df.rdd.isEmpty():
        print("No events found for the provided time range.")
        spark.stop()
        return

    range_label = build_range_label(args)
    output_root = f"{args.output}/{range_label}"

    events_per_minute_df = (
        filtered_df.withColumn("minute_bucket", F.date_trunc("minute", F.col("event_time")))
        .groupBy("minute_bucket")
        .agg(F.count("*").alias("total_events"))
        .orderBy("minute_bucket")
    )

    events_per_hour_df = (
        filtered_df.withColumn("hour_bucket", F.date_trunc("hour", F.col("event_time")))
        .groupBy("hour_bucket")
        .agg(F.count("*").alias("total_events"))
        .orderBy("hour_bucket")
    )

    success_fail_by_type_df = (
        filtered_df.groupBy("event_type")
        .agg(
            F.count("*").alias("total_events"),
            F.sum(F.when(F.col("result") == F.lit("success"), F.lit(1)).otherwise(F.lit(0))).alias("success_events"),
            F.sum(F.when(F.col("result") == F.lit("fail"), F.lit(1)).otherwise(F.lit(0))).alias("fail_events"),
        )
        .withColumn("success_rate", F.round(F.col("success_events") / F.col("total_events"), 4))
        .withColumn("fail_rate", F.round(F.col("fail_events") / F.col("total_events"), 4))
        .orderBy("event_type")
    )

    latency_percentiles_df = (
        filtered_df.withColumn("hour_bucket", F.date_trunc("hour", F.col("event_time")))
        .groupBy("hour_bucket")
        .agg(
            F.expr("percentile_approx(latency_ms, 0.5)").alias("latency_p50_ms"),
            F.expr("percentile_approx(latency_ms, 0.95)").alias("latency_p95_ms"),
            F.expr("percentile_approx(latency_ms, 0.99)").alias("latency_p99_ms"),
            F.count("*").alias("total_events"),
        )
        .orderBy("hour_bucket")
    )

    top_workers_df = (
        filtered_df.groupBy("worker_id")
        .agg(F.count("*").alias("total_events"))
        .orderBy(F.desc("total_events"), F.asc("worker_id"))
        .limit(args.top_workers)
    )

    events_per_minute_df.write.mode("overwrite").parquet(f"{output_root}/events_per_minute")
    events_per_hour_df.write.mode("overwrite").parquet(f"{output_root}/events_per_hour")
    success_fail_by_type_df.write.mode("overwrite").parquet(f"{output_root}/success_fail_by_event_type")
    latency_percentiles_df.write.mode("overwrite").parquet(f"{output_root}/latency_percentiles")
    top_workers_df.write.mode("overwrite").parquet(f"{output_root}/top_workers")

    print(f"Analysis completed. Parquet outputs written to: {output_root}")
    spark.stop()


if __name__ == "__main__":
    main()
