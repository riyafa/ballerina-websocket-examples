import ballerina/log;
import ballerina/http;

const string NAME = "NAME";
int count = 1;
// Stores the connection IDs of users who join the chat.
map<http:WebSocketCaller> connectionsMap = {};
@http:WebSocketServiceConfig {
    path: "/chat"
}
service chatApp on new http:WebSocketListener(6502) {
    resource function onOpen(http:WebSocketCaller caller) {
        json message = {
            ^"type": "id",
            id: caller.id
        };
        var err = caller->pushText(message);
        if (err is error) {
            log:printError("Error occurred when sending text", err = err);
        }
        connectionsMap[caller.id] = caller;
    }

    // Broadcast the messages sent by a user.
    resource function onText(http:WebSocketCaller caller, json msg) {
        if (msg.^"type".toString() == "message") {
            msg.name = getAttributeStr(caller, NAME);
            msg.text = msg.text.toString().replaceAll("(<([^>]+)>)", "");
        } else if (msg.^"type".toString() == "username") {
            string name = msg.name.toString();
            if (!isUsernameUnique(name)) {
                msg.^"type" = "rejectusername";
                msg.name = name + count;
                count += 1;
            }
            caller.attributes[NAME] = msg.name;
            sendUserListToAll();
        }
        broadcast(msg);
    }

    // Broadcast that a user has left the chat once a user leaves the chat.
    resource function onClose(http:WebSocketCaller caller, int statusCode, string reason) {
        _ = connectionsMap.remove(caller.id);
        sendUserListToAll();
    }

    resource function onError(http:WebSocketCaller caller, error err) {
        _ = connectionsMap.remove(caller.id);
        log:printError("Error occured", err = err);
        sendUserListToAll();
    }
}


function broadcast(json msg) {
    foreach var (id, con) in connectionsMap {
        var err = con->pushText(msg);
        if (err is error) {
            log:printError("Error occurred when sending message", err = err);
        }
    }
}

function getAttributeStr(http:WebSocketCaller ep, string key) returns (string) {
    var name = <string>ep.attributes[key];
    return name;
}

function sendUserListToAll() {
    string[] users = [];
    int i = 0;
    foreach var (id, con) in connectionsMap {
        users[i] = getAttributeStr(con, NAME);
        i = i + 1;
    }
    json userMsg = {
        "type": "userlist",
        users: users
    };
    broadcast(userMsg);
}

function isUsernameUnique(string name) returns boolean {
    boolean isUnique = true;
    foreach var (id, con) in connectionsMap {
        if (con.attributes[NAME] != ()) {
            if (getAttributeStr(con, NAME) == name) {
                isUnique = false;
                break;
            }
        }
    }
    return isUnique;
}
