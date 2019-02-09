import ballerina/http;
import ballerina/log;
import ballerina/runtime;
import ballerina/task;
import ballerina/math;

task:Timer? timer;
map<http:WebSocketCaller> consMap = {};
type Event record {
    boolean ^"left";
    boolean ^"right";
    boolean up;
    boolean down;
    !...
};

type Player record {
    int x;
    int y;
    string color;
    !...
};
map<Player> players = {};
@http:WebSocketServiceConfig {
    path: "/game"
}
service chatApp on new http:WebSocketListener(9090) {
    boolean first = true;
    resource function onOpen(http:WebSocketCaller caller) {
        if (self.first) {
            timer = new task:Timer(broadcast, handleError, 1000 / 60, delay = 30);
            self.first = false;
            timer.
            start();
        }
        log:printInfo("Client[" + caller.id + "] joined");
        players[caller.id] = {
                x: 300,
                y: 300,
                color: getRandomColor()
        };
        consMap[caller.id] = caller;
    }

    resource function onText(http:WebSocketCaller caller, Event event) {
        var player = players[caller.id];
        if (player is Player) {

            if (event.^"left") {
                player.x = player.x - 5;
            }
            if (event.up) {
                player.y = player.y - 5;
            }
            if (event.^"right") {
                player.x = player.x + 5;
            }
            if (event.down) {
                player.y = player.y + 5;
            }
        } else {
            panic error("Player has to be initialized");
        }
    }
    resource function onClose(http:WebSocketCaller caller, int statusCode, string reason) {
        log:printInfo("Client[" + caller.id + "] left");
        _ = consMap.remove(caller.id);
        _ = players.remove(caller.id);
    }

    resource function onError(http:WebSocketCaller caller, error err) {
        log:printError("Client[" + caller.id + "] left ", err = err);
        _ = consMap.remove(caller.id);
        _ = players.remove(caller.id);
    }
}

function broadcast() returns error? {
    json data = check json.convert(players);
    foreach var (id, con) in consMap {
        var err = con->pushText(data);
        if (err is error) {
            log:printError("Error sending message", err = err);
        }
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
