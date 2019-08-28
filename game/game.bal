import ballerina/http;
import ballerina/log;
import ballerina/math;
import ballerina/task;

type Event record {|
    boolean 'left;
    boolean 'right;
    boolean up;
    boolean down;
|};

type Player record {|
    int x;
    int y;
    string color;
|};
boolean first = true;
task:Scheduler timer = new ({intervalInMillis: 1000 / 60, initialDelayInMillis: 30});
map<http:WebSocketCaller> consMap = {};
map<Player> players = {};

@http:WebSocketServiceConfig {
    path: "/game"
}
service chatApp on new http:Listener(9090) {
    resource function onOpen(http:WebSocketCaller caller) {
        if (first) {
            first = false;
            var err = timer.attach(broadcast);
            if (err is error) {
                log:printError("Error attaching timer", err = err);
                return;
            }
            err =  timer.start();
            if (err is error) {
            log:printError("Error starting timer", err = err);
        }
        }
        log:printInfo("Client [" + caller.getConnectionId() + "] joined");
        players[caller.getConnectionId()] = {
            x: 300,
            y: 300,
            color: getRandomColor()
        };
        consMap[caller.getConnectionId()] = caller;
    }

    resource function onText(http:WebSocketCaller caller, Event event) {

        var player = players[caller.getConnectionId()];
        if (player is Player) {

            if (event.'left) {
                player.x = player.x - 5;
            }
            if (event.up) {
                player.y = player.y - 5;
            }
            if (event.'right) {
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
        log:printInfo("Client[" + caller.getConnectionId() + "] left");
        _ = consMap.remove(caller.getConnectionId());
        _ = players.remove(caller.getConnectionId());
    }

    resource function onError(http:WebSocketCaller caller, error err) {
        log:printError("Client[" + caller.getConnectionId() + "] left ", err = err);
        _ = consMap.remove(caller.getConnectionId());
        _ = players.remove(caller.getConnectionId());
    }
}

service broadcast = service {
    resource function onTrigger() returns error? {
        json data = check json.constructFrom(players);
        foreach var con in consMap {
            var err = con->pushText(data);
            if (err is error) {
                log:printError("Error sending message", err = err);
            }
        }
    }
};

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
