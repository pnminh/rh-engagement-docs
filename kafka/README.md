# Set up Kafka ACLs
## Get the Kafka CLI
```
$ wget https://archive.apache.org/dist/kafka/2.2.1/kafka_2.12-2.2.1.tgz
$ tar -xzf kafka_2.12-2.2.1.tgz
```
## Work with Kafka Cluster ACLs
Some examples of using ACLs   

List ACLs
```
$ ./bin/kafka-acls.sh --authorizer-properties zookeeper.connect=ZOO_KEEPER_SERVER:2181 --list
```

Add ACL to allow User with CN=USER(set from the certificate)  to read from the topic dev-es-test and read the resource Group * (all)
```
$ ./bin/kafka-acls.sh --authorizer-properties zookeeper.connect=ZOO_KEEPER_SERVER:2181 --add --allow-principal "User:CN=USER" --operation Read --group=* --topic dev-es-test
```

Add ACL to allow User with CN=USER  from host-1 and host-2 to do all operations any resource group prefixed with  test
```
$ ./bin/kafka-acls.sh --authorizer-properties zookeeper.connect=ZOO_KEEPER_SERVER:2181 --add --allow-principal "User:CN=USER" --allow-host host-1 --allow-host host-2 --operation all --group test --resource-pattern-type prefixed
```

Remove ACL which allows User with CN=USER  from host-1 to do all operations any resource group prefixed with  test
```
$ ./bin/kafka-acls.sh --authorizer-properties zookeeper.connect=ZOO_KEEPER_SERVER:2181 --remove --allow-principal "User:CN=USER" --allow-host host-1 --operation all --group test --resource-pattern-type prefixed
```
# Kafka CLI

## List active brokers
```
$ ./bin/zookeeper-shell.sh z-2.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:2181 ls /brokers/ids
[1, 2, 3]
$ ./bin/zookeeper-shell.sh z-2.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:2181 get /brokers/ids/1
Connecting to z-2.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:2181

WATCHER::

WatchedEvent state:SyncConnected type:None path:null
{"listener_security_protocol_map":{"CLIENT_SECURE":"SSL","REPLICATION":"PLAINTEXT","REPLICATION_SECURE":"SSL"},"endpoints":["CLIENT_SECURE://b-1.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:9094","REPLICATION://b-1-internal.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:9093","REPLICATION_SECURE://b-1-internal.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:9095"],"rack":"usw2-az3","jmx_port":9099,"host":"b-1-internal.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com","timestamp":"1599585794431","port":9093,"version":4}
cZxid = 0x10000004c
ctime = Tue Sep 08 12:23:14 CDT 2020
mZxid = 0x10000004c
mtime = Tue Sep 08 12:23:14 CDT 2020
pZxid = 0x10000004c
cversion = 0
dataVersion = 1
aclVersion = 0
ephemeralOwner = 0x1000004f85c0001
dataLength = 551
numChildren = 0
```
In an example above brokers are set up to SSL.

## List Consummer Groups
If the brokers are set to use SSL, we will see the error without using a custom configs
```
$ ./bin/kafka-consumer-groups.sh --list --bootstrap-server b-1.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:9094
Error: Executing consumer group command failed due to org.apache.kafka.common.KafkaException: Failed to find brokers to send ListGroups
java.util.concurrent.ExecutionException: org.apache.kafka.common.KafkaException: Failed to find brokers to send ListGroups
	at org.apache.kafka.common.internals.KafkaFutureImpl.wrapAndThrow(KafkaFutureImpl.java:45)
	at org.apache.kafka.common.internals.KafkaFutureImpl.access$000(KafkaFutureImpl.java:32)
	at org.apache.kafka.common.internals.KafkaFutureImpl$SingleWaiter.await(KafkaFutureImpl.java:89)
	at org.apache.kafka.common.internals.KafkaFutureImpl.get(KafkaFutureImpl.java:260)
	at kafka.admin.ConsumerGroupCommand$ConsumerGroupService.listGroups(ConsumerGroupCommand.scala:131)
	at kafka.admin.ConsumerGroupCommand$.main(ConsumerGroupCommand.scala:57)
	at kafka.admin.ConsumerGroupCommand.main(ConsumerGroupCommand.scala)
Caused by: org.apache.kafka.common.KafkaException: Failed to find brokers to send ListGroups
	at org.apache.kafka.clients.admin.KafkaAdminClient$22.handleFailure(KafkaAdminClient.java:2617)
	at org.apache.kafka.clients.admin.KafkaAdminClient$Call.fail(KafkaAdminClient.java:620)
	at org.apache.kafka.clients.admin.KafkaAdminClient$TimeoutProcessor.handleTimeouts(KafkaAdminClient.java:736)
	at org.apache.kafka.clients.admin.KafkaAdminClient$AdminClientRunnable.timeoutPendingCalls(KafkaAdminClient.java:804)
	at org.apache.kafka.clients.admin.KafkaAdminClient$AdminClientRunnable.run(KafkaAdminClient.java:1098)
	at java.base/java.lang.Thread.run(Thread.java:834)
Caused by: org.apache.kafka.common.errors.TimeoutException: Timed out waiting for a node assignment.
```
The custom configs can be set with the file:   
`client-ssl.properties`
```
bootstrap.servers=SSL://b-3.ot1v3-msk-dev-f5z3n.exm8yb.c4.kafka.us-west-2.amazonaws.com:9094
security.protocol=SSL
ssl.truststore.location=truststore.jks
ssl.truststore.password=changeMe
ssl.keystore.location=keystore.jks
ssl.keystore.password=changeMe
ssl.client.auth=required
ssl.endpoint.identification.algorithm=
```


```
$ ./bin/kafka_2.12-2.2.1/bin/kafka-consumer-groups.sh --list --bootstrap-server b-1.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:9094 --command-config acls/client-ssl.properties
ot1.platform.entitlement-events-ack-topic-group
```
If the bootstrap-server(broker) uses a self-signed cert, we may need to add the cert into the trusted store, otherwise we may get the error like so:
```
Caused by: org.apache.kafka.common.errors.SslAuthenticationException: SSL handshake failed
Caused by: javax.net.ssl.SSLHandshakeException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```
To add the cert to the trusted store, first download the cert from the broker server. One option is to go to the browser (Firefox works the best in this scenario) and open https://broker_url:port, e.g https://b-1.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:9094. Then add the cert to the trust store:
```
$ keytool --import -trustcacerts -alias kafka_cluster -file acls/kafka_cluster.crt
```

## List topics
```
./bin/kafka-topics.sh --list --zookeeper z-2.aws-msk-cluster.c4.kafka.us-west-2.amazonaws.com:2181
```