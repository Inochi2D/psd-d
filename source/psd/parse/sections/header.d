module psd.parse.sections.header;
import psd.parse;
import psd.parse.io;
import std.exception;

/**
    Parses PSD header
*/
void parseHeader(ref ParserContext ctx) {

    // Make sure that this file has a photoshop header and is the correct version
    enforce(ctx.readStr(4) == "8BPS", "Invalid PSD file signature");
    enforce(ctx.readValue!ushort == 1, "Invalid PSD file version");

    ctx.stream.skip(6); // Reserved bytes

    // Read channels
    ctx.psd.channels = ctx.readValue!ushort;
    
    // NOTE: Photoshop flips width/height order for some reason
    ctx.psd.height = ctx.readValue!int;
    ctx.psd.width = ctx.readValue!int;

    ctx.psd.bpc = ctx.readValue!ushort;

    // TODO: Support maybe CMYK
    enforce(ctx.readValue!ushort == 3, "Only RGB/RGBA files are supported currently!");
}