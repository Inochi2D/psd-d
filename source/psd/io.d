module psd.io;
import std.stdio;
import std.bitmanip;
/**
    Reads file value in big endian fashion
*/
T readValue(T)(ref File file) {
    return bigEndianToNative!T(file.rawRead(new ubyte[T.sizeof])[0..T.sizeof]);
}

/**
    Reads a string
*/
string readStr(ref File file, uint length) {
    return cast(string)file.rawRead(new ubyte[length]);
}

string peekStr(ref File file, uint length) {
    string val = file.readStr(length);
    file.seek(-(length+1), SEEK_CUR);
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
    Peeks a value
*/
ubyte[] peek(ref File file, uint length) {
    return file.rawRead(new ubyte[length]);
}

/**
    Skips bytes
*/
void skip(ref File file, uint length) {
    file.seek(length, SEEK_CUR);
}