//module psd.old.loader;
//import psd.layer;
//import psd.io;
//import psd;
//import std.exception;
//import std.format;
//import std.math;
//
///**
//    PSD magic bytes
//*/
//enum PSD_MAGIC = "8BPS";
//
///**
//    Loads a photoshop document from file
//*/
//PSD loadPSD(string file) {
//    import std.file : read;
//
//    File f = File(file);
//    scope (exit)
//        f.close();
//    return loadPSD(f);
//}
//
///**
//    Loads PSD from file handle
//*/
//PSD loadPSD(ref File file) {
//    PSD psd;
//    enforce(file.readStr(4) == PSD_MAGIC, "Invalid PSD signature!");
//    enforce(file.readValue!short == 1, "Invalid PSD version!");
//    file.seek(6, SEEK_CUR); // Skip reserved bits
//
//    // Read channel, width, height, depth and color mode
//    psd.channels = file.readValue!ushort;
//    psd.height = file.readValue!int;
//    psd.width = file.readValue!int;
//    psd.bitsPerChannel = file.readValue!ushort;
//    psd.colorMode = file.readValue!ColorMode;
//
//
//    psd.loadColorSection(file);
//
//    // TODO: read image resources section
//    file.skip(file.readValue!uint);
//    //file.seek(file.readValue!uint, SEEK_CUR); // Skips Image Resources Section
//
//    psd.loadLayerSection(file);
//    writeln(file.tell());
//
//    psd.loadImageData(file);
//
//    return psd;
//}
//
//void loadColorSection(ref PSD psd, ref File file) {
//    uint length = file.readValue!uint;
//    if (length != 0) {
//        psd.colorData = file.rawRead(new ubyte[length]);
//    }
//}
//
//void loadLayerSection(ref PSD psd, ref File file) {
//    uint pos = cast(uint) file.tell();
//    uint len = file.readValue!uint;
//    
//    psd.loadLayers(file);
//
//    file.move(pos + len + 4);
//
//    // Global Layer Masks would be here
//
//    // Extra tagged data would be here
//}
//
//void loadLayers(ref PSD psd, ref File file) {
//    uint pos = cast(uint) file.tell();
//    uint len = file.readValue!uint;
//
//    short layerCount = file.readValue!short;
//    if (layerCount < 0) {
//        psd.mergedAlpha = true;
//        layerCount *= -1;
//    }
//
//    size_t layerIdx;
//    while (layerIdx < layerCount - 1) {
//        psd.layers ~= loadLayer(file, layerIdx, layerCount);
//    }
//
//    foreach (layer; psd.layers) {
//        file.loadLayerTexture(layer);
//    }
//
//    // Seek to end of the layers region, just in case.
//    file.move(pos + len + 4);
//}
//
//ChannelInfo loadChannelInfo(ref File file) {
//    ChannelInfo info;
//    info.id = file.readValue!short;
//    info.dataLength = file.readValue!uint;
//    return info;
//}
//
//Layer loadLayer(ref File file, ref size_t loaded, size_t layerCount) {
//    Layer layer;
//    loaded++;
//    foreach (i; 0 .. 4) {
//        layer.bounds[i] = file.readValue!uint;
//    }
//
//    // Read channel info
//    ushort channels = file.readValue!ushort;
//    foreach (i; 0 .. channels) {
//        layer.channels ~= loadChannelInfo(file);
//    }
//
//    string sig = file.readStr(4);
//    enforce(sig == "8BIM", "Invalid blend mode signature " ~ sig);
//    layer.blending = cast(BlendingMode) file.readStr(4);
//
//    layer.opacity = file.readValue!ubyte;
//    layer.clipping = file.readValue!bool;
//    layer.flags = file.readValue!LayerFlags;
//
//    file.skip(1); // Skip 0 filler
//    uint len = file.readValue!uint;
//    uint pos = cast(uint) file.tell();
//    file.skip(file.readValue!uint);
//    file.skip(file.readValue!uint);
//    layer.name = file.readStr(file.readValue!ubyte);
//    file.seek(pos + len, SEEK_SET);
//
//    writeln(layer);
//
//    if (layer.name == "</Layer set>") {
//        while (true) {
//            Layer l = loadLayer(file, loaded, layerCount);
//            if (l.name != "</Layer set>" && l.isLayerGroup()) {
//                layer.name = l.name;
//                break;
//            }
//
//            layer.children ~= l;
//        }
//    }
//    return layer;
//}
//
//void loadLayerTexture(ref File file, ref Layer layer) {
//
//    //writeln(file.tell());
//    writeln(layer.name, " ", layer.width, " ", layer.height, " ", layer.channels);
//
//    layer.data = new ubyte[layer.dataLengthUncompressed()];
//
//    // Layer groups don't have their own texture data so we'll go in to their children
//    if (layer.isLayerGroup()) {
//
//        file.skip(2 * layer.channels.length);
//
//        foreach (child; layer.children) {
//            file.loadLayerTexture(child);
//        }
//
//        file.skip(2 * layer.channels.length);
//
//        return;
//    }
//    file.loadImageLayer(layer);
//
//    import imagefmt;
//    write_image("test/"~layer.name ~ ".png", layer.width, layer.height, layer.data, 4);
//}
//
//
//void loadImageData(ref PSD psd, ref File file) {
//
//    // Get compression
//    psd.fullImage = new ubyte[psd.width*psd.height*psd.channels];
//    file.loadImageRGB(psd.fullImage, psd.width, psd.height, psd.channels);
//
//    import imagefmt;
//    write_image("test/test.png", psd.width, psd.height, psd.fullImage, 4);
//}