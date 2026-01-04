#!/usr/bin/env python3
"""
Word Count PySpark Application

This application reads a text file, counts word frequencies,
and outputs the results sorted by frequency.
"""

import sys
print("DEBUG: wordcount.py version 2.0 - argument checking is commented out")
from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split, lower, col, count


input_path = "file:///opt/spark/work-dir/data/sample-text.txt"  # Input path
output_path = "file:///tmp/wordcount-output"  # Output path

def main():
    # # Validate command-line arguments
    # if len(sys.argv) != 3:
    #     print("Usage: wordcount.py <input_path> <output_path>", file=sys.stderr)
    #     sys.exit(1)

    # input_path = sys.argv[1]
    # output_path = sys.argv[2]

    print(f"Starting Word Count Application")
    print(f"Input path: {input_path}")
    print(f"Output path: {output_path}")

    # Create Spark session
    spark = SparkSession.builder \
        .appName("WordCount") \
        .getOrCreate()

    try:
        # Read input text file
        print("Reading input file...")
        text_df = spark.read.text(input_path)

        # Perform word count
        print("Processing word count...")
        words_df = text_df.select(
            explode(split(lower(col("value")), r'\W+')).alias("word")
        ).filter(col("word") != "")

        word_counts = words_df.groupBy("word") \
            .agg(count("*").alias("count")) \
            .orderBy(col("count").desc())

        # Cache for multiple operations
        word_counts.cache()

        # Get total word count
        total_words = word_counts.agg({"count": "sum"}).collect()[0][0]
        unique_words = word_counts.count()

        print(f"\nWord Count Statistics:")
        print(f"Total words: {total_words}")
        print(f"Unique words: {unique_words}")

        # Show top 20 words in logs
        print("\nTop 20 most frequent words:")
        print("-" * 40)
        top_words = word_counts.limit(20).collect()
        for i, row in enumerate(top_words, 1):
            print(f"{i:2d}. {row['word']:20s} {row['count']:10d}")
        print("-" * 40)

        # Write results to output
        print(f"\nWriting results to {output_path}...")
        word_counts.coalesce(1).write \
            .mode("overwrite") \
            .option("header", "true") \
            .csv(output_path)

        print("Word count completed successfully!")

    except Exception as e:
        print(f"Error during word count processing: {e}", file=sys.stderr)
        raise
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
