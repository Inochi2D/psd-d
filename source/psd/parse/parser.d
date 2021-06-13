module psd.parse.parser;
import psd.parse.sections;
import psd.parse.io;
import psd;
import std.stdio : File;

/**
    Parse a PSD file
*/
PSD parsePSD(Stream stream) {
    return parsePSDToCtx(stream).psd;
}

/**
    Parse a PSD file
*/
PSD parsePSD(string file) {
    auto f = File(file, "r");
    scope(exit) f.close();
    return parsePSD(new FileStream(f));
}

/**
    Parse a PSD file
*/
ParserContext parsePSDToCtx(string file) {
    auto f = File(file, "r");
    scope(exit) f.close();
    return parsePSDToCtx(new FileStream(f));
}

/**
    Parse a PSD file
*/
ParserContext parsePSDToCtx(Stream stream) {
    ParserContext ctx;
    ctx.stream = stream;

    // Parse the header
    parseHeader(ctx);

    // The color mode data section is useless for us
    ctx.skip(ctx.readValue!uint);

    // Parse image resources (need it for layer tags)
    parseImageResources(ctx);

    // Layer & Mask info
    // This is where the layers we need are!!
    parseLayerMaskInfo(ctx);
    
    return ctx;
}

/**
    Parser context
*/
struct ParserContext {
    /**
        Parser stream
    */
    Stream stream;

    /**
        The main output PSD file
    */
    PSD psd;

    /**
        The image resources
    */
    ImageResourceBlock[] imageResources;

    /**
        Layer mask information
    */
    LayerMaskInfo layerMaskInfo;

    /**
        Proxy for stream.read
    */
    pragma(inline, true)
    ubyte[] read(size_t length) {
        return stream.read(length);
    }

    /**
        Proxy for stream.readValue
    */
    pragma(inline, true)
    T readValue(T)() {
        return stream.readValue!T;
    }

    /**
        Proxy for stream.readStr
    */
    pragma(inline, true)
    string readStr(size_t length) {
        return stream.readStr(cast(uint)length);
    }


    /**
        Proxy for stream.readPascalStr
    */
    pragma(inline, true)
    string readPascalStr() {
        return stream.readPascalStr();
    }

    /**
        Proxy for stream.peekStr
    */
    pragma(inline, true)
    string peekStr(size_t length) {
        return stream.peekStr(cast(uint)length);
    }

    /**
        Proxy for stream.skip
    */
    pragma(inline, true)
    void skip(ptrdiff_t length) {
        return stream.skip(length);
    }

    /**
        Proxy for stream.seek
    */
    pragma(inline, true)
    void seek(ptrdiff_t position) {
        return stream.seek(position);
    }

    /**
        Proxy for stream.tell
    */
    pragma(inline, true)
    size_t tell() {
        return stream.tell();
    }

}