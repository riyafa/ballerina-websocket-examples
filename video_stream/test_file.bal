import ballerina/io;
function getFileChannel(string filePath,
                        io:Mode permission) returns io:ByteChannel {
    io:ByteChannel channel = io:openFile(filePath, permission);
    return channel;
}
function readBytes(io:ByteChannel channel,
                   int numberOfBytes) returns (blob, int) {
    var result = channel.read(numberOfBytes);
    match result {
        (blob, int) content => {
            return content;
        }
        error readError => {
            throw readError;
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
function copy(io:ByteChannel src, io:ByteChannel dst) {
    int bytesChunk = 10000;
    int numberOfBytesWritten = 0;
    int readCount = 0;
    int offset = 0;
    blob readContent;
    boolean doneCoping = false;
    try {
        while (!doneCoping) {
            (readContent, readCount) = readBytes(src, 1000);
            if (readCount <= 0) {
                doneCoping = true;
            }
            numberOfBytesWritten = writeBytes(dst, readContent);
        }
    } catch (error err) {
        throw err;
    }
}function main(string... args) {
    string srcFilePath = "/home/riyafa/Videos/Fun/Internship Experience at WSO2 2015_2016.mkv";
    string dstFilePath = "/home/riyafa/Videos/Fun/test.mkv";
    io:ByteChannel sourceChannel = getFileChannel(srcFilePath, io:READ);
    io:ByteChannel destinationChannel = getFileChannel(dstFilePath, io:WRITE);
    try {
        io:println("Start to copy files from " + srcFilePath + " to " +
                dstFilePath);
        copy(sourceChannel, destinationChannel);
        io:println("File copy completed. The copied file could be located in " +
                dstFilePath);
    } catch (error err) {
        io:println("error occurred while performing copy " + err.message);
    } finally {
        match sourceChannel.close() {
            error sourceCloseError => {
                io:println("Error occured while closing the channel: " +
                        sourceCloseError.message);
            }
            () => {
                io:println("Source channel closed successfully.");
            }
        }
        match destinationChannel.close() {
            error destinationCloseError => {
                io:println("Error occured while closing the channel: " +
                        destinationCloseError.message);
            }
            () => {
                io:println("Destination channel closed successfully.");
            }
        }
    }
}
