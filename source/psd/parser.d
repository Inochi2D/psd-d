module psd.parser;
import utils.io;
import utils;
import psd;
import std.exception;

/**
    Parses a Photoshop Document
*/
PSD parseDocument(ref File file) {
    PSD psd;
    file.seek(0); // Seek back to start of file, just in case.

    // First, parse the header section.
    parseHeader(file, psd);

    // Parse the various sections
    parseColorModeSection(file, psd);
    parseImageResourceSection(file, psd);
    parseLayerMaskInfoSection(file, psd);

    return psd;
}

private:

/*
                                PSD HEADER
*/
void parseHeader(ref File file, ref PSD psd) {
    
    // Check signature
    {
        enforce(file.readStr(4) == "8BPS", "Invalid file, must be a Photoshop PSD file. PSB's are not supported!");
    }

    // Check version (must be 1)
    {
        enforce(file.readValue!ushort() == 1, "Version does not match 1.");
    }

    // Check reserve bytes
    {
        enforce(file.read(6) == [0, 0, 0, 0, 0, 0], "Unexpected reserve bytes, file may be corrupted.");
    }

    // Read number of channels
    // This is the number of channels contained in the document for all layers, including alpha channels.
    // e.g. for an RGB document with 3 alpha channels, this would be 3 (RGB) + 3 (Alpha) = 6 channels
    // however, note that the individual layers can have extra channels for transparency masks, vector masks, and user masks.
    // this is different from layer to layer.
    psd.channels = file.readValue!ushort;

    // Read rest of header info
    psd.height = file.readValue!uint;
    psd.width = file.readValue!uint;
    psd.bitsPerChannel = file.readValue!ushort;
    psd.colorMode = cast(ColorMode)file.readValue!ushort;
}




/*
                                COLOR MODE DATA
*/
void parseColorModeSection(ref File file, ref PSD psd) {
    psd.colorModeDataSectionOffset = file.tell();
    psd.colorModeDataSectionLength = file.readValue!uint;

    file.skip(psd.colorModeDataSectionLength);
}




/*
                                IMAGE RESOURCES
*/
void parseImageResourceSection(ref File file, ref PSD psd) {
    psd.imageResourceSectionOffset = file.tell();
    psd.imageResourceSectionLength = file.readValue!uint;

    file.skip(psd.imageResourceSectionLength);
}






/*
                                LAYER MASK INFO
*/
void parseLayerMaskInfoSection(ref File file, ref PSD psd) {
    psd.layerMaskInfoSectionOffset = file.tell();
    psd.layerMaskInfoSectionLength = file.readValue!uint;
    
    // Parse the length of the layer info section
    uint layerInfoSectionLength = file.readValue!uint;
    LayerMaskSection* layerMaskSection = parseLayer(file, psd, layerInfoSectionLength);

    // TODO: Build hirearchy

    psd.layers = layerMaskSection.layers;
}

LayerMaskSection* parseLayer(ref File file, ref PSD psd, uint dataLength) {
    LayerMaskSection* layerMaskSection = new LayerMaskSection;
    layerMaskSection.kind = 128u;
    layerMaskSection.hasTransparencyMask = false;

    if (dataLength != 0) {
        
        // Read the layer count. If it is a negative number, its absolute value is the number of the layers and the
        // first alpha channel contains the transparency data for the merged result.
        // this will also be reflected in the channelCount of the document.
        short layerCount = file.readValue!short;
        layerMaskSection.hasTransparencyMask = (layerCount < 0);
        if (layerCount < 0) layerCount *= -1;

        layerMaskSection.layerCount = cast(uint)layerCount;
        layerMaskSection.layers = new Layer[layerCount];

        foreach(i; 0..layerMaskSection.layerCount) {
            Layer* layer = &layerMaskSection.layers[i];
            layer.type = LayerType.Any;

            layer.y = file.readValue!int;
            layer.x = file.readValue!int;
            layer.bottom = file.readValue!int;
            layer.right = file.readValue!int;

            // Number of channels in the layer.
            // this includes channels for transparency, layer, and vector masks, if any.
            const ushort channelCount = file.readValue!ushort;
            layer.channels = new ChannelInfo[channelCount];

            foreach(j; 0..channelCount) {
                ChannelInfo* channel = &layer.channels[j];
                channel.id = file.readValue!short;
                channel.dataLength = file.readValue!uint;
            }



        }
    }

    return layerMaskSection;
}




/*
                                IMAGE DATA
*/
void parseImageDataSectionOffset(ref File file, ref PSD psd) {
    psd.imageDataSectionOffset = file.tell();
    psd.imageDataSectionLength = file.size() - psd.imageDataSectionOffset;

    // TODO: read
}