package fure.hxx;

using Lambda;

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

	public function push(item:Any) {
		if (Std.isOfType(item, Flat)) {
			var arr = (item : Flat).arr;
			for (item in new Inner(arr))
				push(item);
			return this.length;
		} else {
			return this.push(item);
		}
	}

	@:from
	public static inline function ofFlat(flat:Flat):Inner
		return flat.arr;

	@:op([]) public inline function get(index:Int):Any
		return this[index];

	@:op([]) public inline function set(index:Int, value:Any)
		return this[index] = value;
}
