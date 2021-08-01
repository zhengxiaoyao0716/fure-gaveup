package fure.collection;

function toIterator(v:Dynamic):Null<Iterator<Any>> {
	if (Std.isOfType(v, Array))
		return v.iterator();
	if (Reflect.isFunction(v.iterator))
		return v.iterator();
	if (Reflect.isFunction(v.next) && Reflect.isFunction(v.hasNext))
		return cast(v);
	return null;
}
