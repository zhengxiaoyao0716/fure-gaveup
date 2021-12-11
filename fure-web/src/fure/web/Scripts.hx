package fure.web;

import fure.web.Element;

abstract Scripts(Elements<String>) {
	public function new(srcs:VarArgs<String>) {
		this = new Elements<String>('script', srcs, src -> ['src' => src], _ -> null);
	}
}
