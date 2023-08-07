package fure.http;

import fure.http.Server.Address;
import haxe.http.HttpMethod;
import haxe.io.Bytes;

typedef Url = String;

@:structInit class Request {
	public final url:Url;
	public final body:Bytes;
	public final method:HttpMethod;
	public final remote:Address;
}
