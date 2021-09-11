import std.stdio;
import psd;
import asdf;
import std.file : getcwd;
import std.file : write;
import psd.parse.parser;

void main()
{
	writeln(getcwd());
	auto ctx = parsePSDToCtx("luna.psd");
	writeln("Hello");
	auto prettyJson = serializeToJsonPretty(ctx);
	write("psd.json", prettyJson);
}
