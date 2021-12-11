package fure.ds;

@:forward(iterator, length)
abstract VarArgs<T>(Array<T>) from Array<T> to Array<T> {
	@:from
	public static inline function ofArg<T>(arg:T):VarArgs<T>
		return [arg];

	public inline function isEmpty():Bool
		return this.length == 0;
}

class Flat {
	public final arr:Array<Any>;

	public function new(arr:Array<Any>) {
		this.arr = [];
		for (item in arr)
			push(item);
	}

	public function push(item:Any) {
		if (Std.isOfType(item, Array)) {
			var arr = (item : Array<Any>);
			for (item in arr)
				push(item);
			return this.arr.length;
		} else {
			return this.arr.push(item);
		}
	}

	public inline function isEmpty():Bool
		return arr.length == 0;

	public inline function iterator():Iterator<Any>
		return arr.iterator();
}

@:forward(iterator, length)
abstract Inner(Array<Any>) to Array<Any> {
	@:from
	public function new(arr:Array<Any>) {
		this = [];
		for (item in arr)
			push(item);
	}

	@:from
	public static function ofOne<T>(one:T):Inner
		return [one];

	public function push(item:Any) {
		if (Std.isOfType(item, Flat)) {
			var arr = (item : Flat).arr;
			for (item in (arr : Inner))
				push(item);
			return this.length;
		} else {
			return this.push(item);
		}
	}

	public inline function isEmpty():Bool
		return this.length == 0;

	@:from
	public static inline function ofFlat(flat:Flat):Inner
		return flat.arr;

	@:op([]) public inline function get(index:Int):Any
		return this[index];

	@:op([]) public inline function set(index:Int, value:Any)
		return this[index] = value;
}

function toIterator(v:Dynamic):Null<Iterator<Any>> {
	if (Std.isOfType(v, Array))
		return v.iterator();
	if (Reflect.isFunction(v.iterator))
		return v.iterator();
	if (Reflect.isFunction(v.next) && Reflect.isFunction(v.hasNext))
		return cast(v);
	return null;
}

function equals<V>(one:V, oth:V):Bool {
	if (one == oth)
		return true;
	if (Reflect.isEnumValue(one) && Reflect.isEnumValue(oth))
		return Type.enumEq(cast(one), cast(oth));
	var one_iter = toIterator(one);
	if (one_iter == null)
		return false;
	var oth_iter = toIterator(oth);
	if (oth_iter == null)
		return false;
	while (one_iter.hasNext() && oth_iter.hasNext()) {
		var one = one_iter.next(), oth = oth_iter.next();
		if (!equals(one, oth))
			return false;
	}
	return !one_iter.hasNext() && !oth_iter.hasNext();
}

@:using(Lambda, fure.ds.Iter)
@:forward(iterator)
abstract KeyValueIterable<K, V>(Iterable<{key:K, value:V}>) //
	from Iterable<{key:K, value:V}> to Iterable<{key:K, value:V}> {
	@:from
	public static function ofIter<K, V>(iter:StdTypes.KeyValueIterable<K, V>):KeyValueIterable<K, V>
		return {iterator: iter.keyValueIterator};

	@:from
	public static function ofMap<K, V>(map:Map<K, V>):KeyValueIterable<K, V>
		return {iterator: map.keyValueIterator};

	public inline function iterator():Iterator<{key:K, value:V}>
		return this.iterator();
}

inline function keyValueIterable<K, V>(map:Map<K, V>):KeyValueIterable<K, V>
	return map;
