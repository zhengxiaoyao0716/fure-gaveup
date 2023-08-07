package fure.http;

import haxe.Exception;
import fure.rx.Promise;
import fure.http.Router.Route;
import fure.log.Logger;
import fure.http.Router.Routes;

typedef Host = String;
typedef Port = Int;
typedef Address = {host:Host, port:Port};

class Server {
	public var address(default, null):Null<Address>;

	private final routes:Array<Route> = [];
	private final logger:Logger;

	public function new(?logger:Logger) {
		this.logger = logger == null ? Logger.easy({name: Type.getClassName(Server)}) : logger;
	}

	public function addRoutes(routes:Routes):Server {
		for (route in routes) {
			this.routes.push(route);
		}
		// TODO build match tree
		return this;
	}

	function invoke(route:Route, request:Request):Promise<Response> {
		return inline route.handler.invoke(request).onFailureThen(error -> {
			logger.error('${route.method} ${route.path} - invoke `${route.name}` failed', error);
			Response.ofCode(InternalServerError);
		});
	}

	public function bind(?address:Address):Promise<Server> {
		if (this.address != null)
			throw new Exception('server has already bind to ${this.address}');
		this.address = {host: '127.0.0.1', port: 0};
		return Promise.resolve(this); // TODO
	}
}
