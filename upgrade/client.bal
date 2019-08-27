import ballerina/http;
import ballerina/io;
import ballerina/log;

public function main() {
    http:WebSocketClient wsClientEp = new("ws://localhost:9090/ws/xyz/Mawanella?age=26",
    config = {callbackService: ClientService, customHeaders:{"X-name":"Riyafa"}, subProtocols:["xml"]});
    var err = wsClientEp->pushText("hello");
    if (err is error) {
        log:printError("Error in sending text", err = err);
    }
}
service ClientService =@http:WebSocketServiceConfig {} service {
resource function onText(http:WebSocketClient conn, string text, boolean finalFrame) {
        io:println(text);
    }
};
