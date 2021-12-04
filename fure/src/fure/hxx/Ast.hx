package fure.hxx;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

using Lambda;

@:using(fure.hxx.Ast.AstTools)
enum Ast {
	Node(offset:Offset, tag:String, props:() -> Ast, inner:() -> Array<Ast>);
	Flat(offset:Offset, inner:() -> Array<Ast>);
	Code(offset:Offset, src:String);
}

abstract Offset(Array<Int>) from Array<Int> {
	public inline function new(offset:Array<Int>)
		this = offset;

	#if macro
	@:commutative
	@:op(A + B) public function addOffset(pos:Position):Position {
		var infos = Context.getPosInfos(pos);
		var min = infos.min + this[0];
		var max = infos.min + this[1];
		if (max < min)
			max = min;
		else if (infos.max < max)
			max = infos.max;
		return Context.makePosition({file: infos.file, min: min, max: max});
	}
	#end
}

class AstTools {
	public static function dumps(ast:Ast, crt:String):String {
		return switch (ast) {
			case Node(_, tag, props, inner):
				var props = props().dumps(crt);
				var inner = inner();
				if (inner.empty())
					return create(tag, props, crt);
				var inner = inner.map(it -> dumps(it, crt));
				return create(tag, '$props, $inner', crt);
			case Flat(_, inner): 'new fure.hxx.Inner.Flat(${inner().map(it -> dumps(it, crt))})';
			case Code(_, src): src;
		}
	}

	#if macro
	public static inline function parse(ast:Ast, crt:String, pos:Position):Expr
		return Context.parse(ast.dumps(crt), pos);
	#end

	static function create(tag:String, arg:String, crt:String):String {
		var index = tag.lastIndexOf('.') + 1;
		var code = tag.charCodeAt(index);
		var isClass = 'A'.code <= code && code <= 'Z'.code;
		return isClass ? 'new $tag($arg)' : crt == '' ? '$tag($arg)' : '$crt(\'$tag\', $arg)';
	}
}
