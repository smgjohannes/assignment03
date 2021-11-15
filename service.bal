import ballerinax/kafka;
import ballerina/log;

kafka:ConsumerConfiguration consumerConfigs = {
    groupId: "group-id",
    topics: ["courseOutline"],
    pollingInterval: 1,
    autoCommit: true
};

final string DEFAULT_URL = "localhost:9092";

listener kafka:Listener kafkaListener = new (kafka:DEFAULT_URL, consumerConfigs);

service kafka:Service on kafkaListener {
    remote function onConsumerRecord(
        kafka:Caller caller,kafka:ConsumerRecord[] records) returns error? {

        foreach var kafkaRecord in records {
            check processKafkaRecord(kafkaRecord);
        }
    }
}

function processKafkaRecord(kafka:ConsumerRecord kafkaRecord) returns error? {
    byte[] Content = kafkaRecord.value;
    string message = check string:fromBytes(Content);
    log:printInfo("Received Message: " + message);
}
