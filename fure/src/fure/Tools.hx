package fure;

inline function toIterator(v:Dynamic):Null<Iterator<Any>>
	return fure.collection.Iter.toIterator(v);

function equlas<V>(one:V, oth:V):Bool {
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
		if (!equlas(one, oth))
			return false;
	}
	return !one_iter.hasNext() && !oth_iter.hasNext();
}
