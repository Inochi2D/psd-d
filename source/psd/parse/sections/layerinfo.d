module psd.parse.sections.layerinfo;
import psd.parse;
import psd.parse.io;
import std.exception;

struct LayerMaskInfo {
    
}

struct LayerMaskSection {
	LayerMaskInfo[] layers; ///< An array of layers, having layerCount entries.
	uint layerCount = 0; ///< The number of layers stored in the array.

	ushort overlayColorSpace = 0; ///< The color space of the overlay (undocumented, not used yet).
	ushort opacity = 0; ///< The global opacity level (0 = transparent, 100 = opaque, not used yet).
	ubyte kind = 0; ///< The global kind of layer (not used yet).

	bool hasTransparencyMask = false; ///< Whether the layer data contains a transparency mask or not.
}

LayerMaskSection ParseLayerMaskSection(ref ParserContext ctx, ulong sectionOffset, uint sectionLength, uint layerLength) {
    LayerMaskSection section;

    return section; 
}

void parseLayerMaskInfo(ref ParserContext ctx) {
    ctx.seek(ctx.psd.layerMaskInfoSection.offset);
    ulong leftToRead = ctx.psd.layerMaskInfoSection.length;

    auto layer = ParseLayerMaskSection(ctx, 0, 0, ctx.psd.layerMaskInfoSection.length);
}