module psd;

public import psd.parse : parsePSD;
public import psd.layer;
import asdf;
import psd.parse.sections.header;
import psd.parse.sections.imgres;

/**
    Section of the PSD
*/
struct Section {
    /**
        The offset from the start of the file where this section is stored.
    */
	ulong offset;
    
    /**
        The length of the section.
    */
	uint length;
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
    
	/**
        Color mode data section.
    */
    Section colorModeDataSection;

	/**
        Image Resources section.
    */
    Section imageResourcesSection;

	/**
        Layer Mask Info section.
    */
    Section layerMaskInfoSection;

	/**
        Image Data section.
    */
    Section imageDataSection;

	/**
        ImageResourcesData
    */
    ImageResourcesData imageResourcesData;

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
    @serdeIgnore
    ubyte[] fullImage;
}

