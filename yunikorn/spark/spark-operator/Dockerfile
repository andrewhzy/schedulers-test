# Dockerfile for Custom PySpark Word Count Application
# Based on official Apache Spark 4.0.0 image

FROM apache/spark:4.0.0

# Set working directory
WORKDIR /opt/spark/work-dir

# Copy PySpark application code
COPY app/* /opt/spark/work-dir/

# Copy sample data for testing
COPY data/sample-text.txt /opt/spark/work-dir/data/

# Ensure proper permissions for non-root user (185)
USER root
RUN chown -R 185:185 /opt/spark/work-dir
USER 185

# Set default command (overridden by SparkApplication)
CMD ["/opt/spark/bin/spark-submit", "/opt/spark/work-dir/spark-test-dynamic-allocation.py"]
