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
    union {
        struct {

            /**
                X coordinate of layer
            */
            uint y;

            /**
                Y coordinate of layer
            */
            uint x;

            /**
                Bottom Y coordinate of layer
            */
            uint bottom;

            /**
                Right X coordinate of layer
            */
            uint right;
        }

        /**
            Bounds as array
        */
        uint[4] bounds;
    }

    /**
        Gets the center coordinates of the layer
    */
    uint[2] center() {
        return [
            x+(width/2),
            y+(height/2),
        ];
    }

    /**
        Gets the size of this layer
    */
    uint[2] size() {
        return [
            width,
            height
        ];
    }

    /**
        Width
    */
    uint width() {
        return right-x;
    }

    /**
        Height
    */
    uint height() {
        return bottom-y;
    }

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
        The data of the layer
    */
    @serdeIgnore
    ubyte[] data;

    /**
        Returns true if the layer is a group
    */
    bool isLayerGroup() {
        return (flags & LayerFlags.GroupMask) == 24;
    }

    /**
        Is the layer useful?
    */
    bool isLayerUseful() {
        return !isLayerGroup() && (width != 0 && height != 0);
    }

    /**
        Length of data
    */
    size_t dataLengthUncompressed() {
        return this.area()*channels.length;
    }

    /**
        Gets total data count
    */
    size_t totalDataCount() {
        uint length;
        foreach(channel; channels) length += channel.dataLength;
        return length;
    }

    /**
        Area of the layer
    */
    size_t area() {
        return width * height;
    }
}