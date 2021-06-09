module psd;

public import psd.loader : loadPSD;
public import psd.layer;

/**
    PSD Color Modes
*/
enum ColorMode : ushort {
    Bitmap,
    Grayscale,
    Indexed,
    RGB,
    CMYK,
    Multichannel,
    Duotone,
    Lab
}

/**
    A photoshop file
*/
struct PSD {
    /**
        Amount of channels in file
    */
    short channels;

    /**
        Width of document
    */
    int width;

    /**
        Height of document
    */
    int height;

    /**
        Bits per channel
    */
    ushort bitsPerChannel;

    /**
        Color mode of document
    */
    ColorMode colorMode;

    /**
        Data for color mode
    */
    ubyte[] colorData;

    /**
        Whether alpha is merged
    */
    bool mergedAlpha;

    /**
        Layers
    */
    Layer[] layers;

    /**
        Full image data encoded as 8-bit RGBA
    */
    ubyte[] fullImage;
}

