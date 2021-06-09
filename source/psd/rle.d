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
    Alternate RLE function from Paint.NET's PSD plugin
    
    (This function is based on MIT licensed code)
*/
int decodeRLE(ref File file, ref ubyte[] buffer, int offset, int count) {
    if (!checkBufferRounds(buffer, offset, count)) return 0;
    if (count == 0) return 0;

    int bytesLeft = count;
    int bufferIdx = offset;
    ubyte* p = buffer.ptr;
    while(bytesLeft > 0) {
        byte counter = file.readValue!byte;

        if (counter > 0) {
            int readLength = counter+1;
            if (bytesLeft < readLength) {
                throw new Exception("Raw packet overruns the decode window");
            }

            // Read in to buffer
            p[bufferIdx..bufferIdx+readLength] = file.read(readLength);
            bufferIdx += readLength;
            bytesLeft -= readLength;
        } else if (counter > -128) {
            int runLength = 1 - counter;
            byte value = file.read(1)[0];
            if (runLength > bytesLeft) {
                throw new Exception("RLE packet overruns the decode window");
            }

            auto ptrEnd = p + runLength;
            while(p < ptrEnd) {
                *p = value;
                p++;
            }

            bufferIdx += runLength;
            bytesLeft -= runLength;
        }
    }

    return count - bytesLeft;
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

        // Skip length value
        // file.skip(layer.height * layer.channels.length * 2);

        // Go through every channel and fill it out
        // TODO: Support more than RGBA
        file.loadImageLayerRLE(layer);
        break;
    default: assert(0);
    }
}