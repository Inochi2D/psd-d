module psd.loader;
import psd.layer;
import psd.io;
import psd;
import psd.rle;
import std.exception;
import std.format;
import std.math;

/**
    PSD magic bytes
*/
enum PSD_MAGIC = "8BPS";

/**
    Loads a photoshop document from file
*/
PSD loadPSD(string file) {
    import std.file : read;

    File f = File(file);
    scope (exit)
        f.close();
    return loadPSD(f);
}

/**
    Loads PSD from file handle
*/
PSD loadPSD(ref File file) {
    PSD psd;
    enforce(file.readStr(4) == PSD_MAGIC, "Invalid PSD signature!");
    enforce(file.readValue!short == 1, "Invalid PSD version!");
    file.seek(6, SEEK_CUR); // Skip reserved bits

    // Read channel, width, height, depth and color mode
    psd.channels = file.readValue!ushort;
    psd.height = file.readValue!int;
    psd.width = file.readValue!int;
    psd.bitsPerChannel = file.readValue!ushort;
    psd.colorMode = file.readValue!ColorMode;


    psd.loadColorSection(file);

    // TODO: read image resources section
    file.skip(file.readValue!uint);
    //file.seek(file.readValue!uint, SEEK_CUR); // Skips Image Resources Section

    psd.loadLayerSection(file);

    psd.loadImageData(file);

    return psd;
}

void loadColorSection(ref PSD psd, ref File file) {
    uint length = file.readValue!uint;
    if (length != 0) {
        psd.colorData = file.rawRead(new ubyte[length]);
    }
}

void loadLayerSection(ref PSD psd, ref File file) {
    uint pos = cast(uint) file.tell();
    uint len = file.readValue!uint;
    
    psd.loadLayers(file);

    file.seek(pos + len, SEEK_SET);

    // Global Layer Masks would be here

    // Extra tagged data would be here
}

void loadLayers(ref PSD psd, ref File file) {
    uint pos = cast(uint) file.tell();
    uint len = file.readValue!uint;

    short layerCount = file.readValue!short;
    if (layerCount < 0) {
        psd.mergedAlpha = true;
        layerCount *= -1;
    }

    size_t layerIdx;
    while (layerIdx < layerCount - 1) {
        psd.layers ~= loadLayer(file, layerIdx, layerCount);
    }

    // file.skip(8);
    file.seek(21654);

    foreach (layer; psd.layers) {
        file.loadLayerTexture(layer);
    }

    // Seek to end of the layers region, just in case.
    file.seek(pos + len, SEEK_SET);
}

ChannelInfo loadChannelInfo(ref File file) {
    ChannelInfo info;
    info.id = file.readValue!short;
    info.dataLength = file.readValue!uint;
    return info;
}

Layer loadLayer(ref File file, ref size_t loaded, size_t layerCount) {
    Layer layer;
    loaded++;
    foreach (i; 0 .. 4) {
        layer.bounds[i] = file.readValue!uint;
    }

    // Read channel info
    ushort channels = file.readValue!ushort;
    foreach (i; 0 .. channels) {
        layer.channels ~= loadChannelInfo(file);
    }

    string sig = file.readStr(4);
    enforce(sig == "8BIM", "Invalid blend mode signature " ~ sig);
    layer.blending = cast(BlendingMode) file.readStr(4);

    layer.opacity = file.readValue!ubyte;
    layer.clipping = file.readValue!bool;
    layer.flags = file.readValue!LayerFlags;

    file.skip(1); // Skip 0 filler

    uint pos = cast(uint) file.tell();
    uint extraDataLength = file.readValue!uint;

    uint layerMaskDataLength = file.readValue!uint;
    file.skip(layerMaskDataLength); // Skip Layer Mask Data

    uint layerBlendingRangesDataLength = file.readValue!uint;
    file.skip(layerBlendingRangesDataLength); // Skip Blending Ranges
    
    uint nameLength = file.peekValue!ubyte;
    layer.name = file.readPascalStr();

    uint extraLayerInfoSize = extraDataLength - layerMaskDataLength - layerBlendingRangesDataLength - nameLength - 8u;
    file.skip(extraLayerInfoSize-1);

    return layer;
}

void loadLayerTexture(ref File file, ref Layer layer) {

    writeln(file.tell());
    writeln(layer);

    if (!layer.isLayerUseful) {
        //file.skip(layer.totalDataCount);
        return;
    }

    layer.data = new ubyte[layer.dataLengthUncompressed()];

    file.loadImageLayer(layer);

    import imagefmt;
    write_image("test/" ~ layer.name ~ ".png", layer.width, layer.height, layer.data, 4);
}


void loadImageData(ref PSD psd, ref File file) {

    // Get compression
    psd.fullImage = new ubyte[psd.width*psd.height*psd.channels];
    file.loadImageRGB(psd.fullImage, psd.width, psd.height, psd.channels);

    import imagefmt;
    write_image("test/test.png", psd.width, psd.height, psd.fullImage, 4);
}