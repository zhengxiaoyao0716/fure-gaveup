package fure.web;

import fure.web.Element.Elements;

abstract Scripts(Elements) {
	public function new(srcs:Array<String>) {
		this = [
			for (src in srcs)
				new Element('script', ['src' => src])
		];
	}
}
