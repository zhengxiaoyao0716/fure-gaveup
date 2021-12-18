package fure;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

typedef Optional<T> = fure.rx.Optional<T>;

@:noUsing
macro inline function definedValue(key:ExprOf<String>):ExprOf<String>
	return macro $v{Context.definedValue(key.getValue())};

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
		switch trest.follow() {
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

@:noUsing
inline function toIterator(v:Dynamic):Null<Iterator<Any>>
	return fure.ds.Iter.toIterator(v);

@:noUsing
inline function equals<V>(one:V, oth:V):Bool
	return fure.ds.Iter.equals(one, oth);

inline function keyValueIterable<K, V>(map:Map<K, V>):fure.ds.Iter.KeyValueIterable<K, V>
	return map;
