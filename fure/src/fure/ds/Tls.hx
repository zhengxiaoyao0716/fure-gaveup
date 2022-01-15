package fure.ds;

import haxe.ds.Option;

#if target.threaded
typedef Tls<T> = sys.thread.Tls<T>;
#else
class Tls<T> {
	public var value:T;

	public inline function new() {}
}
#end
