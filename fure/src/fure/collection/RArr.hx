package fure.collection;

import haxe.Exception;

using fure.collection.RArr;

enum Or<A, B> {
	A(a:A);
	B(b:B);
}

/**
 * recursion array node
 */
// enum Node<V> {
// 	Leaf(one:V);
// 	Nest(arr:Iterable<Node<V>>);
// }

private typedef Mark = Array<Int>; // [riseAt1,length1,riseAt2,length2,...]

private typedef Builder = Array<Int>; // [index, size, rise]

/**
 * recursion array
 *
 * raw    : [  A,  [  B,  [  C  ]  ],  [ _ ],  [  [  D  ],  [  E,  F  ],  G ],  H  ]
 * index  : [  0      1      2          (3)          4         5   6      7     8  ]
 * length : [  4      2      1           0          3,3        2                   ]
 * riseAt : [         3      3           4          8 5        7                   ]
 * depth  : [       +1-0   +1-2         +-1        +2-1     +1-0   +0-1  +0-1      ]
 */
@:allow(fure.collection.RArrIterator)
@:using(fure.collection.RArr.RArr)
class RArr<V> {
	final data:Array<V> = [];
	final mark:Map<Int, Mark> = [];
	final stack:Array<Builder> = [];
	public var depth(default, null):Int = 0;

	//#region builder
	public function new() {
		stack.push([-1, 0, 0]);
	}

	public function push(element:V):Int {
		var length = data.push(element);
		appendElement();
		return length;
	}

	public inline function dive(autoRise:Int = 0):Int {
		stack.push([data.length, 0, autoRise]);
		return ++depth;
	}

	public function rise():Int {
		if (depth <= 0)
			throw new Exception('recursion array already closed, depth: $depth, dataLen: ${data.length}.');
		--depth;

		var builder = stack.pop();
		if (builder[2] > 0)
			trace('manually rised before auto rise, depth: $depth, dataLen: ${data.length}, riseCount: ${builder[2]}.');

		var index = builder[0];
		var length = builder[1];
		if (length == 0) data.push(null);
		var riseAt = data.length;
		if (mark.exists(index))
			mark[index].unshift(length);
		else
			mark[index] = [length];
		mark[index].unshift(riseAt);

		return appendElement();
	}

	private inline function appendElement() {
		var builder = stack[stack.length - 1];
		builder[1]++;
		return --builder[2] == 0 ? rise() : depth;
	}
	//#endregion

	//#region array & nodes
	public var length(get, never):Int;

	public inline function get_length():Int {
		return stack[0][1];
	}

	public inline function flat():Array<V> {
		return data;
	}

	public inline function iterator():RArrIterator<V>
		return new RArrIterator(this);

	public static function toArray<V>(elements:Iterable<V>):Array<V> {
		if (Std.isOfType(elements, Array))
			return cast(elements);
		return [for (ele in elements) ele];
	}

	@:noUsing
	public static function from<V, R>(root:Iterable<V>, flat:(val:V) -> Or<R, Iterable<V>>):RArr<R> {
		var vals = root.toArray();
		var rarr = new RArr<R>();
		while (vals.length > 0) {
			switch (flat(vals.shift())) {
				case A(one):
					rarr.push(one);
				case B(_.toArray() => arr):
					rarr.dive(arr.length);
					if (arr.length == 0) rarr.rise();
					vals = arr.concat(vals);
			}
		}
		return rarr;
	}
	//#endregion
}

typedef VOrRIterable<V> = Iterable<Or<V, VOrRIterable<V>>>;
typedef RArrIterable<V> = {iterator:() -> RArrIterator<V>};

@:using(fure.collection.RArr.RArrIterator)
class RArrIterator<V> {
	final rarr:RArr<V>;
	final markX:Null<Int>;
	final markY:Null<Int>;

	public function new(rarr:RArr<V>, ?markX:Int, ?markY:Int) {
		this.rarr = rarr;
		this.markX = markX;
		this.markY = markY;
	}

	var cursor:Int = 0;
	var offset:Int = 0;

	public var length(get, never):Int;

	private function get_length():Int
		return markX == null ? rarr.stack[0][1] : rarr.mark[markX][markY + 1];

	public inline function hasNext():Bool {
		return cursor < length;
	}

	public function next():Or<V, RArrIterable<V>> {
		if (!hasNext())
			return null;
		cursor++;

		var index = markX == null ? offset : markX + offset;
		var mark = rarr.mark[index];
		return if (mark == null) {
			leaf(index);
		} else if (markX == null || offset > 0) {
			nest(mark, index, 0);
		} else if (markY == mark.length - 2) {
			leaf(index);
		} else {
			nest(mark, index, markY + 2);
		}
	}

	private inline function leaf(index:Int):Or<V, RArrIterable<V>> {
		offset++;
		return Or.A(rarr.data[index]);
	}

	private inline function nest(mark:Mark, markX:Int, markY:Int):Or<V, RArrIterable<V>> {
		offset = this.markX == null ? mark[markY] : mark[markY] - this.markX;
		return Or.B({iterator: () -> new RArrIterator(rarr, markX, markY)});
	}

	public static inline function toRArr<V>(root:VOrRIterable<V>):RArr<V> {
		return RArr.from(root, val -> val);
	}

	public inline function copy():RArrIterator<V> {
		var iter = new RArrIterator(rarr, markX, markY);
		iter.cursor = cursor;
		iter.offset = offset;
		return iter;
	}

	public static inline function skip<V, I:Iterator<V>>(iter:I, num:Int):I {
		for (i in 0...num)
			iter.next();
		return iter;
	}

	public static inline function take<V>(iter:Iterator<V>, num:Int):Array<V> {
		return [for (i in 0...num) iter.next()];
	}
}
