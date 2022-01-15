package fure.ds;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

using Lambda;

@:using(fure.ds.Ast)
enum Ast {
	Node(offset:Offset, tag:String, props:() -> Ast, inner:() -> Array<Ast>);
	Flat(offset:Offset, inner:() -> Array<Ast>);
	Code(offset:Offset, src:String, extra:String);
}

abstract Offset(Array<Int>) from Array<Int> {
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

function dumps(ast:Ast, crt:String):String {
	return switch ast {
		case Node(_, tag, props, inner):
			var bind;
			var props = switch props() {
				case Code(_, src, extra):
					bind = extra;
					src;
				case _ => props:
					bind = '';
					props.dumps(crt);
			}
			var inner = inner();
			if (inner.empty())
				return create(tag, bind, props, crt);
			var inner = inner.map(it -> dumps(it, crt));
			if (inner.length == 1)
				return create(tag, bind, '$props, ${inner[0]}', crt);
			return create(tag, bind, '$props, $inner', crt);
		case Flat(_, inner): 'new fure.ds.Iter.Flat(${inner().map(it -> dumps(it, crt))})';
		case Code(_, src, _): src;
	}
}

#if macro
inline function parse(ast:Ast, crt:String, pos:Position):Expr
	return Context.parse(ast.dumps(crt), pos);
#end

private function create(tag:String, bind:String, arg:String, crt:String):String {
	var index = tag.lastIndexOf('.') + 1;
	var code = tag.charCodeAt(index);
	var isClass = 'A'.code <= code && code <= 'Z'.code;
	var node = isClass ? 'new $tag($arg)' : crt == '' ? '$tag($arg)' : '$crt(\'$tag\', $arg)';
	return bind + node;
}
