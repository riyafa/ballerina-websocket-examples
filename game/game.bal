import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/runtime;
import ballerina/task;
import ballerina/math;

json players = {};
task:Timer? timer;
map<http:WebSocketListener> consMap;
type event record {
   boolean ^"left";
    boolean ^"right";
    boolean up;
    boolean down;
};

@http:WebSocketServiceConfig {
    path: "/game"
}
service<http:WebSocketService> game bind { port: 9090 } {
    boolean first = true;
    onOpen(endpoint ep) {
        if(first){
            timer = new task:Timer(broadcast, handleError, 1000 / 60, delay = 30);
            first = false;
            timer.start();
        }
        io:println("Client["+ep.id+"] joined");
        players[ep.id] = {
            "x": 300,
            "y": 300,
            "color": getRandomColor()
        };
        consMap[ep.id] = ep;
    }

    onText(endpoint ep, string text) {
        //log:printInfo(text);
        event data = check <event>getJson(text, "UTF-8");
        json player = players[ep.id];
        if (data.^"left"){
            player.x = (check <int>player.x) - 5;
        }
        if (data.up){
            player.y = (check <int>player.y) - 5;
        }
        if (data.^"right"){
            player.x = (check <int>player.x) + 5;
        }
        if (data.down) {
            player.y = (check <int>player.y) + 5;
        }
    }
    onClose(endpoint caller, int statusCode, string reason) {
        io:println("Client["+caller.id+"] left");
        _ = consMap.remove(caller.id);
        players.remove(caller.id);
    }
}

function getJson(string content, string encoding) returns json {
    io:StringReader reader = new io:StringReader(content, encoding = encoding);
    json result = check reader.readJson();
    var closeResult = reader.close();
    return result;
}

function broadcast() {
    endpoint http:WebSocketListener ep;
    string text = players.toString();
    foreach id, con in consMap {
        ep = con;
        ep->pushText(text) but {
            error e => log:printError("Error sending message", err = e)
        };
    }
}

function getRandomColor() returns string {
    string[] letters = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
    string color = "#";
    int i = 0;
    while (i < 6) {
        color = color + letters[math:round((math:random() * 15))];
        i = i + 1;
    }
    return color;
}

function handleError(error e){
    log:printError("Error when broadcasting", err=e);
}
