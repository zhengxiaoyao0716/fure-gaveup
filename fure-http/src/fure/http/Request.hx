package fure.http;

import haxe.http.HttpMethod;
import haxe.io.Bytes;

typedef Url = String;
typedef Host = String;
typedef Port = Int;
typedef Address = {host:Host, port:Port};

@:structInit class Request {
	public final url:Url;
	public final body:Bytes;
	public final method:HttpMethod;
	public final remote:Address;
}
