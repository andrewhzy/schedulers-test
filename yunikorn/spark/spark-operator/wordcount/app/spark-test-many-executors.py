from pyspark.sql import SparkSession
import time
import argparse

parser = argparse.ArgumentParser(description='Test Spark dynamic allocation')
parser.add_argument('--sleep-seconds', type=int, default=30,
                    help='Sleep time in seconds for each task (default: 30)')
args = parser.parse_args()

spark = SparkSession.builder.appName("DynamicAllocationTest").getOrCreate()
sc = spark.sparkContext

def sleep_task(x):
    """Simulate long-running task"""
    time.sleep(args.sleep_seconds)
    return x

# # Job 1: Small workload
# job1_partitions = 1
# print(f"Job 1 starting.  Params: range={job1_partitions}, partitions={job1_partitions}, sleep_seconds={args.sleep_seconds}")
# result = sc.parallelize(range(job1_partitions), job1_partitions).map(sleep_task).collect()
# print(f"Job 1 completed. Result: {result}")

# # Job 2: Medium workload
# job2_partitions = 2
# print(f"Job 2 starting.  Params: range={job2_partitions}, partitions={job2_partitions}, sleep_seconds={args.sleep_seconds}")
# result = sc.parallelize(range(job2_partitions), job2_partitions).map(sleep_task).collect()
# print(f"Job 2 completed. Result: {result}")

# # Job 3: Large workload
# job3_partitions = 4
# print(f"Job 3 starting.  Params: range={job3_partitions}, partitions={job3_partitions}, sleep_seconds={args.sleep_seconds}")
# result = sc.parallelize(range(job3_partitions), job3_partitions).map(sleep_task).collect()
# print(f"Job 3 completed. Result: {result}")

# Job 4: Large workload
job4_partitions = 8
print(f"Job 4 starting.  Params: range={job4_partitions}, partitions={job4_partitions}, sleep_seconds={args.sleep_seconds}")
result = sc.parallelize(range(job4_partitions), job4_partitions).map(sleep_task).collect()
print(f"Job 4 completed. Result: {result}")

spark.stop()
