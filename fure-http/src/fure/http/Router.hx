package fure.http;

import haxe.http.HttpMethod;
import fure.rx.Promise;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

@:autoBuild(fure.http.Router.build())
interface Router {
	function routes():Routes;
}

typedef Route = {
	method:Null<HttpMethod>,
	name:String,
	handler:Handler,
	path:String,
	extra:Array<Dynamic>,
};

@:forward
abstract Routes(Array<Route>) from Array<Route> to Array<Route> {
	@:from
	public static function ofRouter(router:Router):Routes
		return router.routes();
}

@:forward
abstract Handler((request:Request) -> Promise<Response>) from(request:Request) -> Promise<Response> {
	@:from
	public static function simple(func:Request->Promise<Any>):Handler
		return r -> func(r).onSuccessThen(v -> Response.guess(v));

	public inline function invoke(request:Request):Promise<Response>
		return Promise.invoke(this.bind(request));
}

#if macro
private inline function isRouteMeta(meta:MetadataEntry):Bool
	return meta.name.substr(0, 6) == ':route';

private function build() {
	var type = Context.getLocalType();
	var cls = type.follow().getClass();
	var root = macro '';
	for (meta in cls.meta.get()) {
		if (isRouteMeta(meta))
			root = meta.params[0];
	}
	var fields = Context.getBuildFields();
	var routes = [];
	for (field in fields) {
		switch field.kind {
			case FFun(f):
				for (meta in field.meta) {
					if (!isRouteMeta(meta))
						continue;
					var mname = meta.name.substr(7);
					var method = macro @:pos(meta.pos) $i{mname == '' ? 'null' : mname};
					var fname = field.name;
					var name = macro @:pos(field.pos) $v{fname};
					var handler = macro @:pos(field.pos) this.$fname;
					var path = meta.params[0];
					var path = if (path == null) {
						Context.warning('missing route path', meta.pos);
						root;
					} else {
						macro @:pos(field.pos) $root + $path;
					}
					var extra = macro @:pos(meta.pos) $a{meta.params.slice(1)};
					var props:Array<ObjectField> = [
						{field: 'method', expr: method},
						{field: 'name', expr: name},
						{field: 'handler', expr: handler},
						{field: 'path', expr: path},
						{field: 'extra', expr: extra},
					];
					routes.push({expr: EObjectDecl(props), pos: meta.pos});
				}
			case _:
		}
	}
	fields.push({
		name: 'routes',
		access: [APublic],
		pos: Context.currentPos(),
		kind: FFun({
			expr: macro return $a{routes},
			ret: macro:Router.Routes,
			args: [],
		}),
	});
	return fields;
}
#end
