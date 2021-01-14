package fure;

#if macro
import fure.hxx.Hxx;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using Lambda;
#end

class Macro {
	@:noUsing
	public static macro function hxx(expr:Expr):Expr
		return switch (expr) {
			case macro @:markup $v{(src : String)} : new Hxx(src).ast().parse(expr.pos);
			case macro $v{(src : String)} : new Hxx(src).ast().parse(expr.pos);
			case _: Context.error("Hxx markup string expected instead of " + expr.toString(), expr.pos);
		};

	/**
	 * Combine two or more structures
	 * @param rest structures
	 * @return Expr
	 */
	public static macro function combine(rest:Array<Expr>):Expr {
		var pos = Context.currentPos();
		var block = [];
		var cnt = 1;
		// since we want to allow duplicate field names, we use a Map. The last occurrence wins.
		var all = new Map<String, ObjectField>();
		for (rx in rest) {
			var trest = Context.typeof(rx);
			switch (trest.follow()) {
				case TAnonymous(_.get() => tr):
					// for each parameter we create a tmp var with an unique name.
					// we need a tmp var in the case, the parameter is the result of a complex expression.
					var tmp = "tmp_" + cnt;
					cnt++;
					var extVar = macro $i{tmp};
					block.push(macro var $tmp = $rx);
					for (field in tr.fields) {
						var fname = field.name;
						all.set(fname, {field: fname, expr: macro $extVar.$fname});
					}
				default:
					return Context.error("Object type expected instead of " + trest.toString(), rx.pos);
			}
		}
		var result = {expr: EObjectDecl(all.array()), pos: pos};
		block.push(macro $result);
		return macro $b{block};
	}
}
