import std.stdio;
import psd;
import asdf;
import std.file : exists, mkdir;
import imagefmt;
import std.path;

void main(string[] args)
{
	string file = args[1];
	string outputFolder = file.stripExtension();
	PSD doc = parseDocument(file);

	if (!outputFolder.exists) {
		mkdir(outputFolder);
	}
	
	foreach(layer; doc.layers) {
		
		// Skip non-image layuers
		if (layer.type != LayerType.Any) continue;

		layer.extractLayerImage();
		write_image(buildPath(outputFolder, layer.name~".png"), layer.width, layer.height, layer.data, 4);
	}

	write(buildPath(outputFolder, outputFolder~".json"), serializeToJsonPretty(doc));
}
