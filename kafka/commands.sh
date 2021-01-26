# test with the default user
./bin/kafka-topics.sh --list --zookeeper z-1.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:2181

# test with a specific user/principal (listed in the cert file)
./bin/kafka-topics.sh --list --zookeeper z-1.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:2181 --command-config acls/hos30-entity-processing/client-ssl.properties

# require to write/read from brokers
./bin/kafka-acls.sh --authorizer-properties zookeeper.connect=z-1.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:2181 --add --allow-principal "User:CN=hos30-entity-processing" --operation all --topic=*

# required to talk to brokers due to handshake issue
keytool --import -trustcacerts -alias kafka_cluster -file kafka_cluster.crt -keystore truststore.jks

./bin/kafka-console-producer.sh --topic test-mp --broker-list b-3.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:9094,b-2.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:9094,b-1.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:9094 --producer.config acls/hos30-entity-processing/client-ssl.properties

# required to access consumer groups
./bin/kafka-acls.sh --authorizer-properties zookeeper.connect=z-1.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:2181 --add --allow-principal "User:CN=hos30-entity-processing" --operation all --group=*

./bin/kafka-console-consumer.sh --topic test-mp --from-beginning --bootstrap-server b-3.aws-msk-cluster-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:9094 --consumer.config acls/hos30-entity-processing/client-ssl.properties

# list acls
kafka-acls.sh --list --authorizer-properties zookeeper.connect=zookeeper_host:2181
