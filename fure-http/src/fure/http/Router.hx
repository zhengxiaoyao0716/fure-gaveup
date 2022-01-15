package fure.http;

import fure.log.Logger;
import fure.rx.Promise;

@:using(fure.http.Router)
enum Route {
	GET(name:String, handler:Handler, path:String);
	POST(name:String, handler:Handler, path:String);
}

@:autoBuild(fure.Router.build())
interface Router extends fure.Router<Route> {}

abstract Handler((request:Request) -> Promise<Response>) //
	from(request:Request) -> Promise<Response> //
	to(request:Request) -> Promise<Response> //
{
	@:from
	public static function simple(func:() -> Promise<Any>):Handler
		return _request -> func().onSuccessThen(v -> Response.guess(v));
}

function invoke(route:Route, request:Request):Promise<Response> {
	return switch route {
		case GET(name, handler, path):
			_invoke(request, name, handler, path);
		case POST(name, handler, path):
			_invoke(request, name, handler, path);
	}
}

private final logger = Logger.easy({name: 'fure.http'});

private function _invoke(request:Request, name:String, handler:(request:Request) -> Promise<Response>, path:String):Promise<Response> {
	return Promise.invoke(handler.bind(request)) //
		.onFailureThen(error -> {
			logger.error('$path - invoke `$name` failed', error);
			Response.ofCode(InternalServerError);
		});
}
