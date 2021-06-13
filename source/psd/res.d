module psd.res;
import asdf;



//
//          LAYER
//


/**
    Photoshop blending modes
*/
enum BlendingMode : string {
    PassThrough = "pass",
    Normal = "norm",
    Dissolve = "diss",
    Darken = "dark",
    Multiply = "mul ",
    ColorBurn = "idiv",
    LinearBurn = "lbrn",
    DarkerColor = "dkCl",
    Lighten = "lite",
    Screen = "scrn",
    ColorDodge = "div ",
    LinearDodge = "lddg",
    LighterColor = "lgCl",
    Overlay = "over",
    SoftLight = "sLit",
    HardLight = "hLit",
    VividLight = "vLit",
    LinearLight = "lLit",
    PinLight = "pLit",
    HardMix = "hMix",
    Difference = "diff",
    Exclusion = "smud",
    Subtract = "fsub",
    Divide = "fdiv",
    Hue = "hue ",
    Saturation = "sat ",
    Color = "colr",
    Luminosity = "lum "
}

/**
    Flags for a layer
*/
enum LayerFlags : ubyte {
    TransProtect    = 0b00000001,
    Visible         = 0b00000010,
    Obsolete        = 0b00000100,
    ModernDoc       = 0b00001000,
    PixelIrrel      = 0b00010000,

    /**
        Special mask used for getting whether a layer is a group layer
        flags & GroupMask = 24, for a layer group.
    */
    GroupMask       = 0b00011000
}

/**
    Information about color channels
*/
struct ChannelInfo {
    /**
        ID of channel
    */
    short id;

    /**
        Length of data in color channel
    */
    uint dataLength;

    /**
        Gets whether the channel is a mask
    */
    bool isMask() {
        return id < -1;
    }

    /**
        Gets whether the channel is an alpha channel
    */
    bool isAlpha() {
        return id == -1;
    }
}

/**
    Information about a layer
*/
struct LayerInfo {

    /**
        Name of the layer
    */
    string name;
    
    /**
        Y/Top coordinate
    */
    uint y;
    
    /**
        X/Left coordinate
    */
    uint x;

    /**
        Y+Height/Bottom coordinate
    */
    uint bottom;

    /**
        X+Width/Right coordinate
    */
    uint right;
}

struct LayerExtInfo {
    string id;
    ubyte[] data;
}



//
//          LAYER DATA
//

/**
    The compression used by the layer
*/
enum LayerCompression : ubyte {
    RAW = 0x00,
    RLE = 0x01,
    ZIP0 = 0x02,
    ZIP1 = 0x03
}

/**
    Data for a layer
*/
struct LayerData {

    /**
        Compression scheme used
    */
    LayerCompression compression;

    /**
        Original bits per channel
    */
    ubyte bpc;

    /**
        Amount of channels
    */
    ushort channels;

    /**
        Width of layer data
    */
    uint width;

    /**
        Height of layer data
    */
    uint height;

    /**
        8 bit RGBA data
    */
    ubyte[] data;
}