module psd.layer;
import asdf;

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
        return id < 0;
    }
}

enum LayerFlags : ubyte {
    TransProtect    = 0b00000001,
    Visible         = 0b00000010,
    Obsolete        = 0b00000100,
    ModernDoc       = 0b00001000,
    PixelIrrel      = 0b00010000,

    GroupMask       = 0b00011000
}

/**
    A layer
*/
struct Layer {
    /**
        Name of layer
    */
    string name;

    /**
        Bounding box for layer
    */
    uint[4] bounds;

    /**
        Blending mode
    */
    BlendingMode blending;

    /**
        Channels in layer
    */
    ChannelInfo[] channels;

    /**
        Opacity of the layer
    */
    ubyte opacity;

    /**
        Whether clipping is base or non-base
    */
    bool clipping;

    /**
        Flags for the layer
    */
    @serdeProxy!uint
    LayerFlags flags;

    /**
        Layers that are the children of this layer
    */
    Layer[] children;

    /**
        The data of the layer
    */
    ubyte[] data;
}