import std.stdio;
import psd;
import asdf;
import std.file : write;
import psd.parse.parser;

void main()
{
	write("test/psd.json", serializeToJsonPretty(parsePSDToCtx("luna.psd")));
}
