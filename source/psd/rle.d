module psd.rle;
import psd.layer;
import utils.io;
import std.exception;
import std.format;

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