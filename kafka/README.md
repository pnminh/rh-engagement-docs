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