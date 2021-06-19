module psd.rle;
import psd.layer;
import psd.io;
import std.exception;
import std.format;


/**
    RLE function taken from stb_image
    
    https://github.com/nothings/stb/blob/master/stb_image.h#L5907
*/
bool decodeRLE(ref File file, ubyte* p, int pixelCount) {
    int count, nleft, len;

    count = 0;
    while ((nleft = pixelCount - count) > 0) {
        len = file.readValue!ubyte;
        if (len == 128) {
            // No-op.
        } else if (len < 128) {
            // Copy next len+1 bytes literally.
            len++;
            if (len > nleft)
                return false; // corrupt data
            count += len;
            while (len) {
                *p = file.readValue!ubyte;
                p += 4;
                len--;
            }
        } else if (len > 128) {
            ubyte val;
            // Next -len+1 bytes in the dest are replicated from next source byte.
            // (Interpret len as a negative 8-bit int.)
            len = 257 - len;
            if (len > nleft)
                return false; // corrupt data
            val = file.readValue!ubyte;
            count += len;
            while (len) {
                *p = val;
                p += 4;
                len--;
            }
        }
    }

    return true;
}

/**
    Taken from psd_sdk

    https://github.com/MolecularMatters/psd_sdk/blob/master/src/Psd/PsdDecompressRle.cpp#L18
*/
void decodeRLE(ubyte* src, uint srcSize, ubyte* dest, uint size) {
    import core.stdc.string : memset, memcpy;

    uint bytesRead = 0;
    uint offset = 0;
    while (offset < size) {
        enforce(offset < srcSize, "Malformed RLE data encounter (%s < %s)".format(offset, srcSize));

        uint tag = *src++;
        ++bytesRead;

        if (tag == 0x80) {
            // NO-OP
        } else if (tag > 0x80) {
            uint count = 257 - tag;

            memset(dest + offset, *src++, count);
            offset += count;
            ++bytesRead;
        } else {
            uint count = tag+1;
            memcpy(dest+offset, src, count);
            
            src += count;
            offset += count;
            bytesRead += count;
        }
    }
}

/**
    Check buffer rounds
*/
bool checkBufferRounds(ubyte[] data, int offset, int count) {
    if (offset < 0) return false;
    if (count < 0) return false;
    if (offset + count > data.length) return false;
    return true;
}

/**
    Loads an RLE image expected to be RGB(A)
*/
void loadImageRGB(ref File file, ref ubyte[] array, int width, int height, ushort channels) {
    ushort compression = file.readValue!ushort;
    enforce(compression < 2, "Unsupported compression scheme %s".format(compression));

    size_t pixelCount = width*height;

    switch(compression) {
    case 0:

        foreach (channel; 0..4) {

            ubyte* p = array.ptr + channel;
            if (channel >= channels) {
                for (int i = 0; i < pixelCount; i++)
                    *p = (channel == 3 ? 255 : 0), p += 4;
            } else {
                foreach (i; 0 .. pixelCount) {
                    *p = file.readValue!ubyte, p += 4;
                }
            }
        }

        break;

    case 1:

        // Skip length value
        file.skip(height * channels * 2);

        // Go through every channel and fill it out
        // TODO: Support more than RGBA
        foreach (channel; 0..4) {

            ubyte* p = array.ptr + channel;
            if (channel >= channels) {
                for (int i = 0; i < pixelCount; i++)
                    *p = (channel == 3 ? 255 : 0), p += 4;
            } else {
               if (!file.decodeRLE(p, cast(int)pixelCount)) writeln("Bad RLE data");
            }
        }
        break;
    default: assert(0);
    }
}

/**
    Loads an image fora layer
*/
void loadImageLayer(ref File file, ref Layer layer) {
    ushort compression = file.readValue!ushort;
    enforce(compression < 2, "Unsupported compression scheme %s".format(compression));
    writeln(compression);

    size_t pixelCount = layer.width*layer.height;

    switch(compression) {
    case 0:

        foreach (channel; 0..4) {

            ubyte* p = layer.data.ptr + channel;
            if (channel >= layer.channels.length) {
                for (int i = 0; i < pixelCount; i++)
                    *p = (channel == 3 ? 255 : 0), p += 4;
            } else {
                foreach (i; 0 .. pixelCount) {
                    *p = file.readValue!ubyte, p += 4;
                }
            }
        }

        break;

    case 1:
        writeln("readlayer");

        foreach(channel; 0..4) {
            uint size = layer.width*layer.height;
            ubyte[] planarData = new ubyte[size*2];

            uint rleDataSize = 0;
            foreach(i; 0..layer.height) {
                rleDataSize += file.readValue!ushort;
            }

            writeln("rle=", rleDataSize);

            ubyte* p = layer.data.ptr + channel;
            if (channel >= layer.channels.length) {
                for (int i = 0; i < pixelCount; i++)
                    *p = (channel == 3 ? 255 : 0), p += 4;
            } else {
                ubyte[] rleData = file.read(rleDataSize);

                decodeRLE(rleData.ptr, rleDataSize, planarData.ptr, size);
                // if (!file.decodeRLE(p, cast(int)pixelCount)) writeln("Bad RLE data");
            }
        }
        break;
    default: enforce(0, "Unsupported ZIP compression");
    }
}