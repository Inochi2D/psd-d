module psd.parse.sections.header;
import psd.parse;
import psd.parse.io;
import std.exception;

/**
    PSD Color Modes
*/
enum ColorMode : ushort {
    Bitmap = 0,
    Grayscale = 1,
    Indexed = 2,
    RGB = 3,
    CMYK = 4,
    Multichannel = 7,
    Duotone = 8,
    Lab = 9
}

/**
    Parses PSD header
*/
void parseHeader(ref ParserContext ctx) {

    // Make sure that this file has a photoshop header and is the correct version
    enforce(ctx.readStr(4) == "8BPS", "Invalid PSD file signature");
    enforce(ctx.readValue!ushort == 1, "Invalid PSD file version");
    enforce(ctx.readStr(6) == "\0\0\0\0\0\0", "Invalid PSD reserve bytes.");

    // Read channels
    ctx.psd.channels = ctx.readValue!ushort;
    
    // NOTE: Photoshop flips width/height order for some reason
    ctx.psd.height = ctx.readValue!uint;
    ctx.psd.width = ctx.readValue!uint;

    ctx.psd.bitsPerChannel = ctx.readValue!ushort;
    ctx.psd.colorMode = cast(ColorMode)ctx.readValue!ushort;

    // TODO: Support maybe CMYK
    enforce(ctx.psd.colorMode == ColorMode.RGB, "Only RGB/RGBA files are supported currently!");

	ctx.psd.colorModeDataSection.length = ctx.readValue!uint;
    ctx.psd.colorModeDataSection.offset = cast(ulong)ctx.tell();
    ctx.skip(ctx.psd.colorModeDataSection.length);

	ctx.psd.imageResourcesSection.length = ctx.readValue!uint;
    ctx.psd.imageResourcesSection.offset = cast(ulong)ctx.tell();
    ctx.skip(ctx.psd.imageResourcesSection.length);

	ctx.psd.layerMaskInfoSection.length = ctx.readValue!uint;
    ctx.psd.layerMaskInfoSection.offset = cast(ulong)ctx.tell();
    ctx.skip(ctx.psd.layerMaskInfoSection.length);

	ctx.psd.imageDataSection.length = cast(uint)(ctx.length() - ctx.tell());
    ctx.psd.imageDataSection.offset = ctx.tell();
}