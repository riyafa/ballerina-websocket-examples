import ballerina/io;
import ballerina/log;
import ballerina/http;

@final string NAME = "NAME";
// Stores the connection IDs of users who join the chat.
map<http:WebSocketListener> connectionsMap;
@http:WebSocketServiceConfig {
    path: "/chat"
}
service<http:WebSocketService> chatApp bind { port: 6502 } {
    onOpen(endpoint caller) {
        json message = { ^"type": "id", id: caller.id };
        caller->pushText(message.toString()) but {
            error e => log:printError("Error sending message", err = e)
        };
        connectionsMap[caller.id] = caller;
    }

    // Broadcast the messages sent by a user.
    onText(endpoint caller, string text) {
        json msg;
        msg = getJson(text);
        if (msg.^"type".toString() == "message"){
            msg.name = getAttributeStr(caller, NAME);
            msg.text = msg.text.toString().replaceAll("(<([^>]+)>)", "");
        } else if (msg.^"type".toString() == "username"){
            caller.attributes[NAME] = msg.name;
            sendUserListToAll();
        }
        broadcast(msg);
    }

    // Broadcast that a user has left the chat once a user leaves the chat.
    onClose(endpoint caller, int statusCode, string reason) {
        _ = connectionsMap.remove(caller.id);
        sendUserListToAll();
    }
}


function broadcast(json msg) {
    endpoint http:WebSocketListener ep;
    foreach id, con in connectionsMap {
        ep = con;
        ep->pushText(msg.toString()) but {
            error e => log:printError("Error sending message", err = e)
        };
    }
}

function getAttributeStr(http:WebSocketListener ep, string key) returns (string) {
    var name = <string>ep.attributes[key];
    return name;
}

function getJson(string content) returns json {
    io:StringReader reader = new io:StringReader(content);
    json result = check reader.readJson();
    var closeResult = reader.close();
    return result;
}

function sendUserListToAll() {
    endpoint http:WebSocketListener ep;
    json users = [];
    int i = 0;
    foreach id, con in connectionsMap {
        users[i] = getAttributeStr(con, NAME);
        i = i + 1;
    }
    json userMsg = { "type": "userlist", users: users };
    broadcast(userMsg);
}