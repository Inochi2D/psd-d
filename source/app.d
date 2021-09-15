import std.stdio;
import psd;
import asdf;
import std.file : write;
import imagefmt;

void main()
{
	PSD doc = parseDocument("luna.psd");

	foreach(layer; doc.layers) {
		layer.extractLayerImage();
		write_image("test/"~layer.name~".png", layer.width, layer.height, layer.data, 4);
	}

	write("test/test.json", serializeToJsonPretty(doc));
}
