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
    Reads file value in big endian fashion
*/
T peekValue(T)(ref File file) {
    T val = file.readValue!T;
    file.skip(-cast(ptrdiff_t)T.sizeof);
    return val;
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


string readPascalStr(ref File file) {
    uint length = file.readValue!ubyte;
    if (length == 0) {
        file.skip(1);
        return "";
    }

    return file.readStr(length);
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
ubyte[] peek(ref File file, ptrdiff_t length) {
    ubyte[] result = file.read(length);
    file.seek(-cast(ptrdiff_t)length, SEEK_CUR);
    return result;
}

/**
    Skips bytes
*/
void skip(ref File file, ptrdiff_t length) {
    file.seek(cast(ptrdiff_t)length, SEEK_CUR);
}