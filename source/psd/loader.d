module psd.loader;
import psd.layer;
import psd.io;
import psd;
import std.file;
import std.stdio;
import std.exception;

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
    scope(exit) f.close();
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
    psd.width = file.readValue!int;
    psd.height = file.readValue!int;
    psd.bitsPerChannel = file.readValue!ushort;
    psd.colorMode = file.readValue!ColorMode;

    psd.loadColorSection(file);

    // TODO: read image resources section
    file.seek(file.readValue!uint, SEEK_CUR); // Skips Image Resources Section

    psd.loadLayerSection(file);

    return psd;
}

void loadColorSection(ref PSD psd, ref File file) {
    uint length = file.readValue!uint;
    if (length != 0) {
        psd.colorData = file.rawRead(new ubyte[length]);
    }
}

void loadLayerSection(ref PSD psd, ref File file) {
    uint pos = cast(uint)file.tell();
    uint len = file.readValue!uint;
    psd.loadLayers(file);
    file.seek(pos+len, SEEK_SET);
    
    // Global Layer Masks would be here

    // Extra tagged data would be here
}

void loadLayers(ref PSD psd, ref File file) {
    uint pos = cast(uint)file.tell();
    uint len = file.readValue!uint;

    short layerCount = file.readValue!short;
    writeln(layerCount);
    if (layerCount < 0) {
        psd.mergedAlpha = true;
        layerCount *= -1;
    }

    int spos = pos;
    size_t layerIdx;
    while(layerIdx < layerCount-1) {
        psd.layers ~= loadLayer(file, layerIdx, layerCount);
    }
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
    foreach(i; 0..4) {
        layer.bounds[i] = file.readValue!uint;
    }

    // Read channel info
    ushort channels = file.readValue!ushort;
    foreach(i; 0..channels) {
        layer.channels ~= loadChannelInfo(file);
    }

    string sig = file.readStr(4);
    enforce(sig == "8BIM", "Invalid blend mode signature "~sig);
    layer.blending = cast(BlendingMode)file.readStr(4);

    layer.opacity = file.readValue!ubyte;
    layer.clipping = file.readValue!bool;
    layer.flags = file.readValue!LayerFlags;
    
    file.skip(1); // Skip 0 filler
    uint len = file.readValue!uint;
    uint pos = cast(uint)file.tell();
    file.skip(file.readValue!uint);
    file.skip(file.readValue!uint);
    layer.name = file.readStr(file.readValue!ubyte);
    file.seek(pos+len, SEEK_SET);
    writeln(loaded, " ", layer.name, " ", layerCount);
    
    if (layer.name == "</Layer set>") {
        while(true) {
            Layer l = loadLayer(file, loaded, layerCount);
            writeln(l.flags);
            if ((l.flags & LayerFlags.GroupMask) == 24) {
                layer.name = l.name;
                break;
            }
            
            layer.children ~= l;
        }
    }
    return layer;
}

void loadLayerTexture(ref File file, ref Layer layer) {
    
}