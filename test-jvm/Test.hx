import haxe.iterators.ArrayIterator;

typedef Typedef1<V> = {function next():V;};
typedef Typedef2<V> = {function next():V;};
typedef TestHasNext<V> = {function hasNext():Bool;};
typedef TestHasNextNoGeneric = {function hasNext():Bool;};
typedef TestIterator<V> = {function iterator():V;};
typedef TestIteratorNoGeneric = {function iterator():Int;}; // no `$Interface`
typedef TestOtherFunc<V> = {function func():V;}; // no `$Interface`
typedef MyIterable<V> = {iterator:() -> ArrayIterator<V>};
typedef MyIterableInherit<V> = {> Iterable<V>, arrayIterator:() -> ArrayIterator<V>};

class Test {
	public static function main() {
		var obj:Typedef2<String> = {next: () -> "test typedef with generic and `next` function"};
		trace(cast(obj : Typedef1<String>)); // `jvm` target not works?

		var iter:MyIterable<Int> = {iterator: () -> [].iterator()};
		trace(cast(iter : Iterable<Int>)); // not inherit `Iterable$Interface`?

		var iter:MyIterableInherit<Int> = {iterator: () -> [].iterator(), arrayIterator: () -> [].iterator()};
		trace(cast(iter : Iterable<Int>)); // WTF?
	}
}
