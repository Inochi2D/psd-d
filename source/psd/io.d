module psd.io;
import std.bitmanip;

public import std.file;
public import std.stdio;

/**
    Reads file value in big endian fashion
*/
T readValue(T)(ref File file) {
    // if (T.sizeof > file.size()-file.tell()) return T.init;
    return bigEndianToNative!T(file.rawRead(new ubyte[T.sizeof])[0 .. T.sizeof]);
}

/**
    Reads a string
*/
string readStr(ref File file, uint length) {
    return cast(string) file.rawRead(new ubyte[length]);
}

/**
    Peeks a string
*/
string peekStr(ref File file, uint length) {
    string val = file.readStr(length);
    file.seek(-(length + 1), SEEK_CUR);
    return val;
}

/**
    Peeks a value
*/
T peekValue(T)(ref File file) {
    T value = file.readValue(file);
    file.seek(-T.sizeof, SEEK_CUR);
    return value;
}

/**
    Reads values
*/
ubyte[] read(ref File file, size_t length) {
    return file.rawRead(new ubyte[length]);
}

/**
    Peeks values
*/
ubyte[] peek(ref File file, size_t length) {
    ubyte[] result = file.read(length);
    file.seek(-length, SEEK_CUR);
    return result;
}

/**
    Skips bytes
*/
void skip(ref File file, size_t length) {
    file.seek(length, SEEK_CUR);
}