package fure;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

private #if !macro macro #end inline function fureVersion():ExprOf<String>
	return macro $v{Context.definedValue('fure')};

final FURE_VERSION = fureVersion();
final FURE_WEBSITE = 'https://github.com/zhengxiaoyao0716/furegame';

inline function orElse<V>(value:Null<V>, ifNull:V):V
	return value == null ? ifNull : value;

inline function orElseGet<V>(value:Null<V>, ifNull:() -> V):V
	return value == null ? ifNull() : value;

/**
 * Combine two or more structures
 * @param rest structures
 * @return Expr
 */
@:noUsing
macro function combine(rest:Array<Expr>):Expr {
	var pos = Context.currentPos();
	var block = [];
	var cnt = 1;
	// since we want to allow duplicate field names, we use a Map. The last occurrence wins.
	var allFields:Array<ObjectField> = [];
	for (rx in rest) {
		var trest = Context.typeof(rx);
		switch (trest.follow()) {
			case TAnonymous(_.get() => tr):
				// for each parameter we create a tmp var with an unique name.
				// we need a tmp var in the case, the parameter is the result of a complex expression.
				var tmp = 'tmp_' + cnt;
				cnt++;
				var extVar = macro $i{tmp};
				block.push(macro var $tmp = $rx);
				for (field in tr.fields) {
					var fname = field.name;
					allFields.push({field: fname, expr: macro $extVar.$fname});
				}
			case _:
				return Context.error('Object type expected instead of ' + trest.toString(), rx.pos);
		}
	}
	var result = {expr: EObjectDecl(allFields), pos: pos};
	block.push(macro $result);
	return macro $b{block};
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

inline function keyValueIterable<K, V>(map:Map<K, V>):Iterable<{key:K, value:V}>
	return {iterator: () -> map.keyValueIterator()};

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
