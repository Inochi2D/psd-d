module psd.parse.sections.imgres;
import psd.parse;
import psd.parse.io;
import std.exception;

//
//          IMAGE RESOURCES
//

/**
    An image resource block
*/
struct ImageResourceBlock {
    /**
        Unique ID
    */
    ushort uid;

    /**
        Name of resource
    */
    string name;

    /**
        Data of resource
    */
    ubyte[] data;
}

/**
    A struct representing a thumbnail as stored in the image resources section.
*/
struct Thumbnail
{
	uint width;
	uint height;
	uint binaryJpegSize;
	ubyte[] binaryJpeg;
}

/**
    A struct representing an alpha channel as stored in the image resources section.
    NOTE: Note that the image data for alpha channels is stored in the image data section.
*/
struct AlphaChannel
{
    enum Mode : ubyte
    {
        ALPHA = 0,			// The channel stores alpha data.
        INVERTED_ALPHA = 1,	// The channel stores inverted alpha data.
        SPOT = 2			// The channel stores spot color data.
    }

    /**
        The channel's ASCII name.
    */
    string asciiName;
	
    /**
        The color space the colors are stored in.
    */
    ushort colorSpace;
	
    /**
        16-bit color data with 0 being black and 65535 being white (assuming RGBA).
    */
    ushort[4] color;
	
    /**
        The channel's opacity in the range [0, 100].
    */
    ushort opacity;
	
    /**
        The channel's mode, one of AlphaChannel::Mode.
    */
    Mode mode;
}

/**
    A struct representing the information extracted from the Image Resources section.
*/
struct ImageResourcesData
{
	/**
        An array of alpha channels, having alphaChannelCount entries.
    */
    AlphaChannel[] alphaChannels;

	/**
        The number of alpha channels stored in the array.
    */
    uint alphaChannelCount;

	/**
        Raw data of the ICC profile.
    */
    ubyte[] iccProfile;
	uint sizeOfICCProfile;

	/**
        Raw EXIF data.
    */
    ubyte[] exifData;
	uint sizeOfExifData;

	/**
        Whether the PSD contains real merged data.
    */
    bool containsRealMergedData;

	/**
        Raw XMP metadata.
    */
    ubyte[] xmpMetadata;

	/**
        JPEG thumbnail.
    */
    Thumbnail thumbnail;
}


enum ImageResourceType
{
    IPTC_NAA = 1028,
    CAPTION_DIGEST = 1061,
    XMP_METADATA = 1060,
    PRINT_INFORMATION = 1082,
    PRINT_STYLE = 1083,
    PRINT_SCALE = 1062,
    PRINT_FLAGS = 1011,
    PRINT_FLAGS_INFO = 10000,
    PRINT_INFO = 1071,
    RESOLUTION_INFO = 1005,
    DISPLAY_INFO = 1077,
    GLOBAL_ANGLE = 1037,
    GLOBAL_ALTITUDE = 1049,
    COLOR_HALFTONING_INFO = 1013,
    COLOR_TRANSFER_FUNCTIONS = 1016,
    MULTICHANNEL_HALFTONING_INFO = 1012,
    MULTICHANNEL_TRANSFER_FUNCTIONS = 1015,
    LAYER_STATE_INFORMATION = 1024,
    LAYER_GROUP_INFORMATION = 1026,
    LAYER_GROUP_ENABLED_ID = 1072,
    LAYER_SELECTION_ID = 1069,
    GRID_GUIDES_INFO = 1032,
    URL_LIST = 1054,
    SLICES = 1050,
    PIXEL_ASPECT_RATIO = 1064,
    ICC_PROFILE = 1039,
    ICC_UNTAGGED_PROFILE = 1041,
    ID_SEED_NUMBER = 1044,
    THUMBNAIL_RESOURCE = 1036,
    VERSION_INFO = 1057,
    EXIF_DATA = 1058,
    BACKGROUND_COLOR = 1010,
    ALPHA_CHANNEL_ASCII_NAMES = 1006,
    ALPHA_CHANNEL_UNICODE_NAMES = 1045,
    ALPHA_IDENTIFIERS = 1053,
    COPYRIGHT_FLAG = 1034,
    PATH_SELECTION_STATE = 1088,
    ONION_SKINS = 1078,
    TIMELINE_INFO = 1075,
    SHEET_DISCLOSURE = 1076,
    WORKING_PATH = 1025,
    MAC_PRINT_MANAGER_INFO = 1001,
    WINDOWS_DEVMODE = 1085
}

/**
    Parses image resources
*/
void parseImageResources(ref ParserContext ctx) {
    ctx.seek(ctx.psd.imageResourcesSection.offset);
    ulong leftToRead = ctx.psd.imageResourcesSection.length;

    while (leftToRead > 0) {
        string signature = ctx.readStr(4);
        
        enforce(signature == "8BIM" || signature == "psdM", 
            "Image resources section seems to be corrupt, signature does not match \"8BIM\" nor \"psdM\".");

        const ushort id = ctx.readValue!ushort;

        const ubyte nameLength = ctx.readPaddedValue!ubyte(2, 1);
        const string name = ctx.readStr(nameLength - 1);
        
        const uint resourceSize = ctx.readPaddedValue!uint();

        switch (id) {
			case ImageResourceType.IPTC_NAA:
			case ImageResourceType.CAPTION_DIGEST:
			case ImageResourceType.PRINT_INFORMATION:
			case ImageResourceType.PRINT_STYLE:
			case ImageResourceType.PRINT_SCALE:
			case ImageResourceType.PRINT_FLAGS:
			case ImageResourceType.PRINT_FLAGS_INFO:
			case ImageResourceType.PRINT_INFO:
			case ImageResourceType.RESOLUTION_INFO:
			case ImageResourceType.GLOBAL_ANGLE:
			case ImageResourceType.GLOBAL_ALTITUDE:
			case ImageResourceType.COLOR_HALFTONING_INFO:
			case ImageResourceType.COLOR_TRANSFER_FUNCTIONS:
			case ImageResourceType.MULTICHANNEL_HALFTONING_INFO:
			case ImageResourceType.MULTICHANNEL_TRANSFER_FUNCTIONS:
			case ImageResourceType.LAYER_STATE_INFORMATION:
			case ImageResourceType.LAYER_GROUP_INFORMATION:
			case ImageResourceType.LAYER_GROUP_ENABLED_ID:
			case ImageResourceType.LAYER_SELECTION_ID:
			case ImageResourceType.GRID_GUIDES_INFO:
			case ImageResourceType.URL_LIST:
			case ImageResourceType.SLICES:
			case ImageResourceType.PIXEL_ASPECT_RATIO:
			case ImageResourceType.ICC_UNTAGGED_PROFILE:
			case ImageResourceType.ID_SEED_NUMBER:
			case ImageResourceType.BACKGROUND_COLOR:
			case ImageResourceType.ALPHA_CHANNEL_UNICODE_NAMES:
			case ImageResourceType.ALPHA_IDENTIFIERS:
			case ImageResourceType.COPYRIGHT_FLAG:
			case ImageResourceType.PATH_SELECTION_STATE:
			case ImageResourceType.ONION_SKINS:
			case ImageResourceType.TIMELINE_INFO:
			case ImageResourceType.SHEET_DISCLOSURE:
			case ImageResourceType.WORKING_PATH:
			case ImageResourceType.MAC_PRINT_MANAGER_INFO:
			case ImageResourceType.WINDOWS_DEVMODE:
				// we are currently not interested in this resource type, skip it
			default:
				// this is a resource we know nothing about, so skip it
				ctx.skip(resourceSize);
				break;
			
			case ImageResourceType.DISPLAY_INFO:
			{
				// the display info resource stores color information and opacity for extra channels contained
				// in the document. these extra channels could be alpha/transparency, as well as spot color
				// channels used for printing.
			
				// check whether storage for alpha channels has been allocated yet
				// (ImageResourceType.ALPHA_CHANNEL_ASCII_NAMES stores the channel names)
				if (ctx.psd.imageResourcesData.alphaChannels.length == 0)
				{
					// note that this assumes RGB mode
					const uint channelCount = ctx.psd.header.channels - 3;
					ctx.psd.imageResourcesData.alphaChannelCount = channelCount;
					ctx.psd.imageResourcesData.alphaChannels.length = channelCount;
				}
			
				const uint versionNum = ctx.readValue!uint;
			
				for (uint i = 0u; i < ctx.psd.imageResourcesData.alphaChannelCount; ++i) {
                    AlphaChannel* channel = &ctx.psd.imageResourcesData.alphaChannels[i];
					channel.colorSpace = ctx.readValue!ushort;
					channel.color[0] = ctx.readValue!ushort;
					channel.color[1] = ctx.readValue!ushort;
					channel.color[2] = ctx.readValue!ushort;
					channel.color[3] = ctx.readValue!ushort;
					channel.opacity = ctx.readValue!ushort;
					channel.mode = cast(AlphaChannel.Mode)ctx.readValue!ubyte;
				}
			}
			break;
			
			case ImageResourceType.VERSION_INFO:
			{
				const uint versionNum = ctx.readValue!uint;
				const ubyte hasRealMergedData = ctx.readValue!ubyte;
				ctx.psd.imageResourcesData.containsRealMergedData = (hasRealMergedData != 0u);
				ctx.skip(resourceSize - 5u);
			}
			break;
			
			case ImageResourceType.THUMBNAIL_RESOURCE:
			{
				const uint format = ctx.readValue!uint;
				const uint width = ctx.readValue!uint;
				const uint height = ctx.readValue!uint;
				const uint widthInBytes = ctx.readValue!uint;
				const uint totalSize = ctx.readValue!uint;
				const uint binaryJpegSize = ctx.readValue!uint;
			
				const ushort bitsPerPixel = ctx.readValue!ushort;
				const ushort numberOfPlanes = ctx.readValue!ushort;
			
				ctx.psd.imageResourcesData.thumbnail.width = width;
				ctx.psd.imageResourcesData.thumbnail.height = height;
				ctx.psd.imageResourcesData.thumbnail.binaryJpegSize = binaryJpegSize;
				ctx.psd.imageResourcesData.thumbnail.binaryJpeg = ctx.readData(binaryJpegSize);
				
				const uint bytesToSkip = resourceSize - 28u - binaryJpegSize;
				ctx.skip(bytesToSkip);
			}
			break;
			
			case ImageResourceType.XMP_METADATA:
			{
				// load the XMP metadata as raw data
                enforce(ctx.psd.imageResourcesData.xmpMetadata.length != 0, "File contains more than one XMP metadata resource.");
				ctx.psd.imageResourcesData.xmpMetadata = ctx.readData(resourceSize);
			}
			break;
			
			case ImageResourceType.ICC_PROFILE:
			{
				// load the ICC profile as raw data
                enforce(ctx.psd.imageResourcesData.iccProfile.length != 0, "File contains more than one ICC profile.");
				ctx.psd.imageResourcesData.iccProfile = ctx.readData(resourceSize);
				ctx.psd.imageResourcesData.sizeOfICCProfile = resourceSize;
			}
			break;
			
			case ImageResourceType.EXIF_DATA:
			{
				// load the EXIF data as raw data
                enforce(ctx.psd.imageResourcesData.exifData.length != 0, "File contains more than one EXIF data block.");
				ctx.psd.imageResourcesData.exifData = ctx.readData(resourceSize);
				ctx.psd.imageResourcesData.sizeOfExifData = resourceSize;
			}
			break;
			
			case ImageResourceType.ALPHA_CHANNEL_ASCII_NAMES:
			{
				// check whether storage for alpha channels has been allocated yet
				// (ImageResourceType.DISPLAY_INFO stores the channel color data)
				if (ctx.psd.imageResourcesData.alphaChannels.length == 0)
				{
					// note that this assumes RGB mode
					const uint channelCount = ctx.psd.header.channels - 3;
					ctx.psd.imageResourcesData.alphaChannelCount = channelCount;
					ctx.psd.imageResourcesData.alphaChannels.length = channelCount;
				}
			
				// the names of the alpha channels are stored as a series of Pascal strings
				uint channel = 0;
				long remaining = resourceSize;
				while (remaining > 0) {
                    string channelName;
					const ubyte channelNameLength = ctx.readValue!ubyte;
					if (channelNameLength > 0) {
                        channelName = ctx.readStr(channelNameLength);
					}
			
					remaining -= 1 + channelNameLength;
			
					if (channel < ctx.psd.imageResourcesData.alphaChannelCount) {
						ctx.psd.imageResourcesData.alphaChannels[channel].asciiName = channelName;
						++channel;
					}
				}
			}
			break;
        }

		leftToRead -= 10 + nameLength + resourceSize;
    }
}