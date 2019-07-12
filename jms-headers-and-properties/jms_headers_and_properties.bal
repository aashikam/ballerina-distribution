import ballerinax/jms;
import ballerina/log;

// Initializes a JMS connection with the provider.
jms:Connection conn = new({
        initialContextFactory:
         "org.apache.activemq.artemis.jndi.ActiveMQInitialContextFactory",
        providerUrl: "tcp://localhost:61616"
    });

// Initializes a JMS session on top of the created connection.
jms:Session jmsSession = new(conn, {
        // An optional property that defaults to `AUTO_ACKNOWLEDGE`.
        acknowledgementMode: "AUTO_ACKNOWLEDGE"
    });

// Initializes a queue receiver using the created session.
listener jms:QueueListener consumerEndpoint = new(jmsSession,
    queueName = "MyQueue");

// Binds the created consumer to the listener service.
service jmsListener on consumerEndpoint {

    // The `OnMessage` resource gets invoked when a message is received.
    resource function onMessage(jms:QueueReceiverCaller consumer,
                                jms:Message message) {
        // Creates a queue sender.
        jms:QueueSender queueSender = new({
                initialContextFactory: 
                "org.apache.activemq.artemis.jndi.ActiveMQInitialContextFactory",
                providerUrl: "tcp://localhost:61616"
            }, queueName = "RequestQueue");

        var content = message.getTextMessageContent();
        if (content is string) {
            log:printInfo("Message Text: " + content);
        } else {
            log:printError("Error retrieving content", err = content);
        }

        // Retrieves the JMS message headers.
        var id = message.getCorrelationID();
        if (id is string) {
            log:printInfo("Correlation ID: " + id);
        } else if (id is ()) {
            log:printInfo("Correlation ID not set");
        } else {
            log:printError("Error getting correlation id", err = id);
        }

        var msgType = message.getType();
        if (msgType is string) {
            log:printInfo("Message Type: " + msgType);
        } else if (msgType is ()) {
            log:printInfo("Message type not provided");
        } else {
            log:printError("Error getting message type", err = msgType);
        }

        // Retrieves the custom JMS string property.
        var size = message.getStringProperty("ShoeSize");
        if (size is string) {
            log:printInfo("Shoe size: " + size);
        } else if (size is ()) {
            log:printInfo("Please provide the shoe size");
        } else {
            log:printError("Error getting string property", err = size);
        }

        // Creates a new text message.
        var msg = queueSender.session.createTextMessage(
                                         "Hello From Ballerina!");
        if (msg is jms:Message) {
            // Sets the JMS header and Correlation ID.
            var cid = msg.setCorrelationID("Msg:1");
            if (cid is error) {
                log:printError("Error setting correlation id",
                    err = cid);
            }

            // Sets the JMS string property.
            var stringProp = msg.setStringProperty("Instruction",
                "Do a perfect Pirouette");
            if (stringProp is error) {
                log:printError("Error setting string property",
                    err = stringProp);
            }
            var result = queueSender->send(msg);
            if (result is error) {
                log:printError("Error sending message to broker",
                    err = result);
            }
        } else {
            log:printError("Error creating message", err = msg);
        }
    }
}