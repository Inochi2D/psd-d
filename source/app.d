import std.stdio;
import psd;
import asdf;
import std.file : getcwd;
import std.file : write;
import psd.parse.parser;

void main()
{
	writeln(getcwd());
	write("test/psd.json", serializeToJsonPretty(parsePSDToCtx("luna.psd")));
}
