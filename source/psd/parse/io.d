module psd.parse.io;
import std.bitmanip;

public import std.file;
public import std.stdio;
import std.traits;

/**
    A stream
*/
abstract class Stream {

    /**
        Reads X amount of bytes from stream

        returns empty array if EOF
    */
    abstract ubyte[] read(size_t length);

    /**
        Gets the position in the stream
    */
    abstract size_t tell();

    /**
        Gets the length of the stream
    */
    abstract size_t length();

    /**
        Sets the position in the stream
    */
    abstract void seek(ptrdiff_t pos);

    /**
        Skips pos amount of bytes in the stream
    */
    abstract void skip(ptrdiff_t pos);

    /**
        Gets whether we're EOF
    */
    final
    bool eof() {
        return tell() == length();
    }

    /**
        Peeks bytes
    */
    final
    ubyte[] peek(size_t length) {
        ubyte[] data = read(length);
        skip(-length);
        return data;
    }
}

/**
    A file stream
*/
class FileStream : Stream {
private:
    File file;

public:
    /**
        Constructs a new file stream
    */
    this(ref File file) {
        this.file = file;
    }

    override
    ubyte[] read(size_t length) {
        return file.rawRead(new ubyte[length]);
    }

    override
    size_t tell() {
        return file.tell();
    }

    override
    void seek(ptrdiff_t offset) {
        file.seek(offset, SEEK_SET);
    }

    override
    void skip(ptrdiff_t offset) {
        if (offset < 0) {
            import std.math : abs;
            file.seek(file.tell()-abs(offset), SEEK_SET);
            return;
        }
        file.seek(offset, SEEK_CUR);
    }

    override
    size_t length() {
        return file.size;
    }
}

// TODO: Memory stream

/**
    Reads file value in big endian fashion
*/
T readValue(T)(ref Stream stream) if(isNumeric!T) {
    return bigEndianToNative!T(stream.read(T.sizeof)[0 .. T.sizeof]);
}

/**
    Peeks a value
*/
T peekValue(T)(ref Stream stream) if(isNumeric!T) {
    T value = bigEndianToNative!T(stream.peek(T.sizeof)[0 .. T.sizeof]);
    stream.skip(-T.sizeof);
    return value;
}

/**
    Reads a string
*/
string readStr(ref Stream stream, uint length) {
    return cast(string) stream.read(length);
}

/**
    Peek oncomming string in stream
*/
string peekStr(ref Stream stream, uint length) {
    string value = stream.readStr(length);
    stream.skip(-cast(int)length);
    return value;
}

/**
    Reads a pascal string
*/
string readPascalStr(ref Stream stream) {
    ubyte length = stream.read(1)[0];
    if (length == 0) {
        // Special case, empty strings are 2 bytes long!
        stream.skip(1);
        return "";
    }

    return stream.readStr(length);
}