import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/runtime;

@http:WebSocketServiceConfig {
    path: "/stream/ws"
}
service<http:WebSocketService> wsService bind { port: 9090 } {
    string dstFilePath = "/home/riyafa/Videos/Fun/";
    io:ByteChannel fileChannel;
    boolean channelClosed = true;
    int fileNum = 1;
    onOpen(endpoint ep) {
        log:printInfo("New client connected");
    }

    onBinary(endpoint ep, blob data, boolean finalFragment) {
        if (channelClosed && !finalFragment){
            fileChannel = untaint getFileChannel(dstFilePath + "file" + fileNum + ".mkv", io:WRITE);
            fileNum = fileNum + 1;
            channelClosed = false;
        }
        _ = writeBytes(fileChannel, data);

        if (finalFragment) {
            match fileChannel.close() {
                error e => io:println("Channel closed");
                () => channelClosed = true;
            }
            if (ep.isOpen){
                _ = ep->close(1000, "File writing complete");
            }
        }
    }
}

function writeBytes(io:ByteChannel channel,
                    blob content,
                    int startOffset = 0) returns int {

    var result = channel.write(content, startOffset);
    match result {
        int numberOfBytesWritten => {
            return numberOfBytesWritten;
        }
        error err => {
            throw err;
        }
    }
}

function getFileChannel(string filePath,
                        io:Mode permission) returns io:ByteChannel {

    io:ByteChannel channel = io:openFile(filePath, permission);
    return channel;
}