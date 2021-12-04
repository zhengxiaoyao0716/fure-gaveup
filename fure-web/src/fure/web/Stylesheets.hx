package fure.web;

import fure.web.Element.Elements;

abstract Stylesheets(Elements) {
	public function new(hrefs:Array<String>) {
		this = [
			for (href in hrefs)
				new Element('link', ['rel' => 'stylesheet', 'href' => href])
		];
	}
}
