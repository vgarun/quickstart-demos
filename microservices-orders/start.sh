#!/bin/bash

# Source library
. ../utils/helper.sh

check_env || exit 1
check_mvn || exit 1
check_running_cp 5.0 || exit 

./stop.sh

confluent start schema-registry

[[ -d "kafka-streams-examples" ]] || git clone https://github.com/confluentinc/kafka-streams-examples.git
(cd kafka-streams-examples && git checkout DEVX-147)
[[ -d "kafka-streams-examples/target" ]] || (cd kafka-streams-examples && mvn clean package -DskipTests)

echo "Starting OrdersService"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.OrdersService -Dexec.args="localhost:9092 http://localhost:8081 localhost 5432" >/dev/null &
sleep 5

echo "Starting PostOrderRequests"
mvn exec:java -f kafka-streams-examples/pom.xml -Dexec.mainClass=io.confluent.examples.streams.microservices.PostOrderRequests -Dexec.args="5432" >/dev/null &
sleep 5

confluent consume orders --value-format avro --max-messages 5
