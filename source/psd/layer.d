module psd.layer;
import psd.res;

import asdf;

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

        /**
            Bounds of the layer
        */
        uint[4] bounds;

        struct {
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
        Gets the center coordinates of the layer
    */
    uint[2] center() {
        return [
            x+(width/2),
            y+(height/2),
        ];
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
        Whether this layer is a group
    */
    bool isGroup;

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
    @serdeIgnore
    ubyte[] data;

    /**
        Length of data
    */
    size_t dataLengthUncompressed() {
        return this.area()*channels.length;
    }

    /**
        Area of the layer
    */
    size_t area() {
        return width * height;
    }
}

