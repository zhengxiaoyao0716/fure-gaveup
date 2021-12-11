package fure.web;

import fure.web.Element;

abstract Stylesheets(Elements<String>) {
	public function new(hrefs:VarArgs<String>) {
		this = new Elements<String>('link', hrefs, href -> ['rel' => 'stylesheet', 'href' => href], _ -> null);
	}
}
