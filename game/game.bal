import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/runtime;
import ballerina/task;
import ballerina/math;

task:Timer? timer;
map<http:WebSocketListener> consMap;
type Event record {
    boolean ^"left",
    boolean ^"right",
    boolean up,
    boolean down,
    !...
};

type Player record {
    int x,
    int y,
    string color,
    !...
};
map<Player> players;
@http:WebSocketServiceConfig {
    path: "/game"
}
service<http:WebSocketService> game bind { port: 9090 } {
    boolean first = true;
    onOpen(endpoint caller) {
        if (first){
            timer = new task:Timer(broadcast, handleError, 1000 / 60, delay = 30);
            first = false;
            timer.start();
        }
        io:println("Client[" + caller.id + "] joined");
        players[caller.id] = {
            x: 300,
            y: 300,
            color: getRandomColor()
        };
        consMap[caller.id] = caller;
    }

    onText(endpoint caller, Event event) {
        Player player;
        match players[caller.id] {
            Player value => player = value;
            () => {error err = { message: "Player has to be initialized" };
            throw err;}
        }
        if (event.^"left"){
            player.x = player.x - 5;
        }
        if (event.up){
            player.y = player.y - 5;
        }
        if (event.^"right"){
            player.x = player.x + 5;
        }
        if (event.down) {
            player.y = player.y + 5;
        }
    }
    onClose(endpoint caller, int statusCode, string reason) {
        io:println("Client[" + caller.id + "] left");
        _ = consMap.remove(caller.id);
        _ = players.remove(caller.id);
    }

    onError(endpoint caller, error err) {
        log:printError ("Client[" + caller.id + "] left ", err = err);
        _ = consMap.remove(caller.id);
        _ = players.remove(caller.id);
    }
}

function broadcast() {
    endpoint http:WebSocketListener ep;
    json data = check <json>players;
    foreach id, con in consMap {
        ep = con;
        ep->pushText(data) but {
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

function handleError(error e) {
    log:printError("Error when broadcasting", err = e);
}
