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
    Will read the signature from the header.
*/
pragma(inline, true)
char[4] readSignature(ref ParserContext ctx) {
    char[4] signature;

    foreach (i; 0 .. 4)
        signature[i] = ctx.readValue!byte;

    return signature;
}

/**
    Will read the reserve bytes from the header.
*/
pragma(inline, true)
char[6] readReserveBytes(ref ParserContext ctx) {
    char[6] reserve;

    foreach (i; 0 .. 6)
        reserve[i] = ctx.readValue!byte;

    return reserve;
}



struct PSD_Header {
    /**
        Signature of the file
    */
    char[4] signature;

    /**
        Amount of channels in file
    */
    short versionNo;

    /**
        Reserved bytes, should be zero
    */
    char[6] reserved;

    /**
        Amount of channels in file
    */
    short channels;

    /**
        Width of document
    */
    uint width;

    /**
        Height of document
    */
    uint height;

    /**
        Bits per channel
    */
    ushort bitsPerChannel;

    /**
        Color mode of document
    */
    ColorMode colorMode;
}

/**
    Parses PSD header
*/
void parseHeader(ref ParserContext ctx) {
    PSD_Header header;
    header.signature = readSignature(ctx);
    byte[4] signatureBytes = [ '8','B','P','S' ];

    // Make sure that this file has a photoshop header and is the correct version
    enforce(signatureBytes == header.signature, "Invalid PSD file signature");

    auto versionNo = ctx.readValue!ushort;
    enforce((1 == versionNo) || (2 == versionNo), "Invalid PSD or PSB file version");
    
    if (2 == versionNo)
        ctx.psd.psbFile = true;
    else 
        ctx.psd.psbFile = false;

    header.reserved = readReserveBytes(ctx);
    byte[6] reserveBytes = [ '\0','\0','\0','\0','\0','\0' ];
    enforce(reserveBytes == header.reserved, "Invalid PSD reserve bytes.");

    // Read channels
    header.channels = ctx.readValue!ushort;
    
    // NOTE: Photoshop flips width/height order for some reason
    header.height = ctx.readValue!uint;
    header.width = ctx.readValue!uint;

    header.bitsPerChannel = ctx.readValue!ushort;
    header.colorMode = cast(ColorMode)ctx.readValue!ushort;

    ctx.psd.header = header;

    // TODO: Support maybe CMYK
    enforce(header.colorMode == ColorMode.RGB, "Only RGB/RGBA files are supported currently!");

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