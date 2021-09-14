module psd.rle;
import psd.layer;
import utils.io;
import std.exception;
import std.format;

/**
    Taken from psd_sdk

    https://github.com/MolecularMatters/psd_sdk/blob/master/src/Psd/PsdDecompressRle.cpp#L18
*/
void decodeRLE(ubyte[] source, ubyte[] destination, uint start = 0, uint stride = 1) {
    import core.stdc.string : memset, memcpy;

    ubyte* dest = destination.ptr+start;
    ubyte* src = source.ptr;

    uint offset = 0;
    uint bytesRead = 0;
    while (offset < destination.length/stride) {
        enforce(bytesRead <= source.length, "Malformed RLE data encounter (%s < %s @ index=%s)".format(offset, source.length, bytesRead));

        const ubyte tag = *src++;
        ++bytesRead;

        if (tag == 0x80) {
            // NO-OP
        } else if (tag > 0x80) {
            const uint count = cast(uint)(257 - cast(int)tag);

            ubyte data = *src++;
            foreach(i; 0..count) *(dest+=stride) = data;

            offset += count;
            ++bytesRead;
        } else {
            const uint count = (cast(uint)tag)+1;

            foreach(i; 0..count) *(dest+=stride) = *src;
            
            src += count;
            offset += count;

            bytesRead += count;
        }
    }
}