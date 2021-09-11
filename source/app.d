import std.stdio;
import psd;
import asdf;
import std.file : write;

void main()
{
	write("test/test.json", serializeToJsonPretty(parseDocument("luna.psd")));
}
