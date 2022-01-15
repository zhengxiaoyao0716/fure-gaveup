package fure.http;

import haxe.http.HttpStatus;
import haxe.Json;
import haxe.io.Mime;
import fure.http.Headers;
import haxe.io.Encoding;
import haxe.io.Bytes;

@:structInit class Response {
	public final body:Bytes;
	public final code:HttpStatus;
	public final headers:Headers;

	public static function ofText(text:String, code = HttpStatus.OK, ?encoding = Encoding.UTF8):Response
		return of(Bytes.ofString(text, encoding), code, TextPlain);

	public static function ofHtml(text:String, code = HttpStatus.OK, ?encoding = Encoding.UTF8):Response
		return inline of(Bytes.ofString(text, encoding), code, TextHtml);

	public static function ofJson(data:Dynamic, code = HttpStatus.OK):Response
		return inline of(Bytes.ofString(Json.stringify(data)), code, ApplicationJson);

	public static function ofCode(code:HttpStatus):Response
		return inline of(Bytes.alloc(0), code, Mime.TextPlain);

	public static function of(body:Bytes, code = HttpStatus.OK, type:Mime = ApplicationOctetStream):Response {
		var headers = Headers.content(body.length, type);
		return {body: body, code: code, headers: headers};
	}

	public static function guess(value:Any):Response {
		return if (Std.isOfType(value, Response)) {
			value;
		} else if (Std.isOfType(value, String)) {
			Response.ofHtml(value);
		} else if (Std.isOfType(value, Int)) {
			Response.ofCode(value);
		} else {
			Response.ofJson(value);
		}
	}
}
