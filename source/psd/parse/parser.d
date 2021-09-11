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
    auto stream = new FileStream(f);
    writeln("Made a stream.");
    auto context = parsePSDToCtx(stream);
    writeln("Parsed");

    return context;
}

/**
    Parse a PSD file
*/
ParserContext parsePSDToCtx(Stream stream) {
    ParserContext ctx;
    ctx.stream = stream;

    // Parse the header
    parseHeader(ctx);
    
    // Parse image resources (need it for layer tags)
    parseImageResources(ctx);
    writeln("Parsed image resources.");

    // Layer & Mask info
    // This is where the layers we need are!!
    parseLayerMaskInfo(ctx);
    writeln("Parsed layer mask info.");
    
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
        Rounds numToRound up to a multiple of multipleOf
    */
    pragma(inline, true)
	T roundUpToMultiple(T)(T numToRound, T multipleOf)
	{
		// make sure that this function is only called for unsigned types, and ensure that we want to round to a power-of-two
		//static_assert(util::IsUnsigned<T>::value == true, "T must be an unsigned type.");
		//PSD_ASSERT(IsPowerOfTwo(multipleOf), "Expected a power-of-two.");

		return (numToRound + (multipleOf - 1u)) & ~(multipleOf - 1u);
	}

    /**
        Proxy for stream.readValue, but padds the result.
    */
    pragma(inline, true)
    T readPaddedValue(T)(T multipleOf = 2, T addTo = 0) {
        T value = stream.readValue!T;
        return cast(T)roundUpToMultiple(value + addTo, multipleOf);
    }

    /**
        Proxy for stream.read
    */
    pragma(inline, true)
    ubyte[] readData(size_t length) {
        return stream.read(length);
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


    /**
        Proxy for stream.size
    */
    pragma(inline, true)
    size_t length() {
        return stream.length();
    }
}