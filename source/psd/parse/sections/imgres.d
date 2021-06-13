module psd.parse.sections.imgres;
import psd.parse;
import psd.parse.io;
import std.exception;

//
//          IMAGE RESOURCES
//

/**
    An image resource block
*/
struct ImageResourceBlock {
    /**
        Unique ID
    */
    ushort uid;

    /**
        Name of resource
    */
    string name;

    /**
        Data of resource
    */
    ubyte[] data;
}

/**
    Parses image resources
*/
void parseImageResources(ref ParserContext ctx) {

    // Length and position info get
    size_t pos = ctx.tell();
    immutable(uint) length = ctx.readValue!uint;


    // We want to continue reading until we've exhausted these
    // They're denoted with this header
    while (ctx.readStr(4) == "8BIM") {

        ImageResourceBlock block;
        block.uid = ctx.readValue!ushort;
        block.name = ctx.readPascalStr;

        size_t dataLen = ctx.readValue!uint; // Read initial data length
        block.data = ctx.read(dataLen);
        
        // We can't trust the provided data length!
        // Read until we see the next tag or are at the end
        if (ctx.peekStr(4) != "8BIM") {
            while (ctx.tell < pos+length && ctx.peekStr(4) != "8BIM") block.data ~= ctx.read(1);
        }
        
        // Add
        ctx.imageResources ~= block;
    }

    // Skip back since that wasn't 8BIM
    ctx.skip(-4);


    // In case we don't fully read the data, skip to the end of the section
    ctx.seek(pos+length);
}