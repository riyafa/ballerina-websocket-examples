import ballerina/io;
import ballerina/log;
import ballerina/http;

@http:WebSocketServiceConfig {
    path: "/basic/ws",
    subProtocols: ["text", "json"],
    idleTimeoutInSeconds: 120
}
service basic on new http:WebSocketListener(9090) {

    // This resource is triggered after a successful client connection.
     resource function onOpen(http:WebSocketCaller caller) {
        io:println("\nNew client connected");
    }

    // This resource is triggered when a new text frame is received from a client.
    resource function onText(http:WebSocketCaller caller, string text, boolean finalFrame) {
        io:println("\nText message: " + text);
        var err = caller->pushText(text);
        if (err is error) {
            log:printError("Error occurred when sending text", err = err);
        }
    }

    // This resource is triggered when a new binary frame is received from a client.
     resource function onBinary(http:WebSocketCaller caller, byte[] binary) {
        io:println("\nNew binary message received");
        var err = caller->pushBinary(binary);
        if (err is error) {
            log:printError("Error occurred when sending binary", err = err);
        }
    }

    // This resource is triggered when a ping message is received from the client. If this resource is not implemented,
    // a pong message is automatically sent to the connected endpoint when a ping is received.
    resource function onPing(http:WebSocketCaller caller, byte[] data) {
        var err = caller->pong(data);
        if (err is error) {
            log:printError("Error occurred when sending pong data", err = err);
        }
    }

    // This resource is triggered when a pong message is received.
     resource function onPong(http:WebSocketCaller caller, byte[] data) {
        io:println("Pong received");
    }

    // This resource is triggered when a particular client reaches the idle timeout that is defined in the
    // `http:WebSocketServiceConfig` annotation.
    resource function onIdleTimeout(http:WebSocketCaller caller) {        
        io:println("\nReached idle timeout");
        io:println("Closing connection " + caller.id);
        var err = caller->close(statusCode = 1001, reason = "Connection timeout");
        if (err is error) {
            log:printError("Error occured when closing the connection", err = err);
        }
    }

    // This resource is triggered when a client connection is closed from the client side.
    resource function onClose(http:WebSocketCaller caller, int statusCode, string reason) {
        io:println("\nClient left with status code " + statusCode + " because " + reason);
    }

     // This resource is triggered when an error occurred in the connection or the transport.
    resource function onError(http:WebSocketCaller caller, error err) {
        log:printError("Error occurred ", err = err);
    }
}
