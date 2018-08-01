import ballerina/io;
import ballerina/http;
import ballerina/runtime;



function main(string... args) {
    endpoint http:WebSocketClient ep {
        url: "ws://localhost:9090/stream/ws",
        callbackService: clientService
    };

    io:println("Client connected");
    string srcFilePath = "/home/riyafa/Videos/Fun/Internship Experience at WSO2 2015_2016.mkv";
    io:ByteChannel channel = getFileChannel(srcFilePath, io:READ);
    try {
        sendFile(channel, ep);
    } catch (error err){
        io:println("error occurred while sending file" + err.message);
    } finally {
        match channel.close() {
            error err => {
                io:println("Error occured while closing the channel: " +
                        err.message);
            }
            () => {
                io:println("Source channel closed successfully.");
            }
        }
    }
}


service<http:WebSocketClientService> clientService {
    onClose(endpoint ep, int statusCode, string reason) {
        io:println(string `{{statusCode}}, {{reason}}`);
    }
}

function getFileChannel(string filePath,
                        io:Mode permission) returns io:ByteChannel {

    io:ByteChannel channel = io:openFile(filePath, permission);
    return channel;
}

function readBytes(io:ByteChannel channel,
                   int numberOfBytes) returns (byte[], int) {

    var result = channel.read(numberOfBytes);
    match result {
        (byte[], int) content => {
            return content;
        }
        error readError => {
            throw readError;
        }
    }
}

function sendFile(io:ByteChannel src, http:WebSocketClient ep) {
    endpoint http:WebSocketClient clientEp = ep;

    int bytesChunk = 30000;
    int readCount = 0;
    byte[] readContent;
    boolean doneCopying = false;
    int count = 0;
    while (!doneCopying) {
        (readContent, readCount) = readBytes(src, bytesChunk);
        if (readCount <= 0) {
            clientEp->pushBinary(readContent, final = true) but {
                error e => io:println(e)
            };
            doneCopying = true;
        } else {
            clientEp->pushBinary(readContent, final = false) but {
                error e => io:println(e)
            };
        }
        runtime:sleep(10);
    }
}

