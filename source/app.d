import std.stdio;
import psd;
import asdf;
import std.file : write;

void main()
{
	write("test/psd.json", serializeToJsonPretty(loadPSD("test.psd")));
}
