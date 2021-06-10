module psd.parse.rle;
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