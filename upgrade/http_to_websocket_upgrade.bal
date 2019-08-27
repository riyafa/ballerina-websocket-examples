import ballerina/http;
import ballerina/io;
import ballerina/log;

@http:ServiceConfig {
    basePath: "/"
}
service httpService on new http:Listener(9090) {

    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/ws/{address}/{city}",
            upgradeService: wsService
        }
    }
    resource function upgrader(http:Caller caller, http:Request req, string address, string city) {
        http:WebSocketCaller wsCaller;
        string headerName = "X-name";
        string headerVal = "";
        if (req.hasHeader(headerName)) {
            headerVal = req.getHeader(headerName);
        }
        if (headerVal == "Riyafa") {
            wsCaller = caller->acceptWebSocketUpgrade({
                "X-hi": "Welcome!!"
            });
            wsCaller.setAttribute("address", address);
            wsCaller.setAttribute("city", city);
            wsCaller.setAttribute("age", req.getQueryParams()["age"]);
        } else {
            var err = caller->cancelWebSocketUpgrade(400, "Invalid name");
            if (err is error) {
                log:printError("Error in canelling handhsake", err = err);
            }
        }
    }

    @http:ResourceConfig {
        path: "/hello",
        methods: ["POST"]
    }
    resource function httpResource(http:Caller caller, http:Request req) returns error? {
        http:Response resp = new;
        var payload = req.getJsonPayload();
        if (payload is error) {
            log:printError("Error sending message", err = payload);
            resp.setPayload("Error in payload");
            resp.statusCode = 500;
        } else {
            io:println(payload);
            resp.setPayload("HTTP POST received:" + <@untiant>payload.toString() + "\n");
        }

        var err = caller->respond(resp);
        if (err is error) {
            log:printError("Error in responding", err = err);
        }
    }
}

service wsService = @http:WebSocketServiceConfig {
    subProtocols: ["xml, json"],
    idleTimeoutInSeconds: 20
} service {

    resource function onOpen(http:WebSocketCaller caller) {
        string msg = "Thank you for joining. Your address: " + caller.getAttribute("address").toString() + ", "
        + caller.getAttribute("city").toString() + ". And you are " + caller.getAttribute("age").toString() + " years of age.";
        var err = caller->pushText(msg);
        if (err is error) {
            log:printError("Error in sending text", err = err);
        }
    }

    resource function onText(http:WebSocketCaller caller, string text) {
        io:println(text);
        var err = caller->pushText(text);
        if (err is error) {
            log:printError("Error sending message", err = err);
        }
    }

};
