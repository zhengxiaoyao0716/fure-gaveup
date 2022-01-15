package fure.http;

import haxe.io.Mime;

enum abstract Header(String) from String to String {
	var ContentLength = 'Content-Length';
	var ContentType = 'Content-Type';
}

abstract Headers(Map<Header, Array<String>>) from Map<Header, Array<String>> to Map<Header, Array<String>> {
	public static function content(length:Int, type:Mime)
		return [ContentLength => [Std.string(length)], ContentType => [type]];

	public function putAll(headers:Map<Header, Array<String>>):Headers {
		for (header => values in headers) {
			put(header, values);
		}
		return this;
	}

	public function put(header:Header, values:Iterable<String>):Headers {
		if (!this.exists(header))
			this[header] = [];
		var vs = this[header];
		for (value in values) {
			vs.push(value);
		}
		return this;
	}

	@:op([])
	public function set(header:Header, values:Array<String>):Array<String>
		return this[header] = values;
}
