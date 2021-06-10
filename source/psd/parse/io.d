module psd.io;
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
        Sets the position in the stream
    */
    abstract void set(ptrdiff_t pos);

    /**
        Skips pos amount of bytes in the stream
    */
    abstract void skip(ptrdiff_t pos);

    /**
        Gets the length of the stream
    */
    abstract void length();

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
    void set(ptrdiff_t offset) {
        file.seek(offset, SEEK_SET);
    }

    override
    void skip(ptrdiff_t offset) {
        file.seek(offset, SEEK_CUR);
    }

    override
    void length() {
        return file.length;
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
    return value;
}

/**
    Reads a string
*/
string readStr(ref Stream stream, uint length) {
    return cast(string) file.read(length);
}