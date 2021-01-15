package fure.hxx;

using Lambda;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.BaseType;
#end

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
	@:op(A + B)
	@:commutative
	public function addOffset(pos:Position):Position {
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
	public static function dumps(ast:Ast):String {
		return switch (ast) {
			case Node(_, tag, props, inner):
				var props = props().dumps();
				var inner = inner == null ? [] : inner();
				var inner = inner.empty() ? '[]' : 'fure.hxx.Ast.Nodes.flat(${inner.map(dumps)})';
				var tag = isClass(tag) ? 'new $tag' : tag;
				'{ var props = $props; var inner = $inner; $tag(props, inner); }';
			case Flat(_, inner): 'new fure.hxx.Ast.Nodes(${inner == null ? [] : inner().map(dumps)})';
			case Code(_, src): src;
		}
	}

	#if macro
	public static function parse(ast:Ast, pos:Position):Expr {
		#if debug
		return switch (ast) {
			case Node(offset, tag, props, inner):
				var exprs = [
					{
						var propsVal = props().parse(pos);
						macro var props = $propsVal;
					},
					{
						var inner = inner == null ? [] : inner();
						if (inner.empty()) {
							macro var inner = [];
						} else {
							var innerVal = macro $a{inner.map(ast -> ast.parse(pos))};
							macro var inner = fure.hxx.Ast.Nodes.flat($innerVal);
						}
					},
					{
						if (isClass(tag)) {
							var type = try {
								Context.getType(tag);
							} catch (error) {
								return Context.error(error.message, pos + offset);
							}
							var type:BaseType = switch (type) {
								case TInst(_.get() => field, _): field;
								case TAbstract(_.get() => field, _): field;
								case _: return Context.error('Tag "${tag}" could not used as Hxx component', pos + offset);
							}
							var path = {name: type.name, pack: type.pack};
							macro new $path(props, inner);
						} else {
							var tag = tag.split('.');
							macro $p{tag}(props, inner);
						}
					}
				];
				macro $b{exprs};
			case Flat(_, inner):
				var innerVal = macro $a{inner == null ? [] : inner().map(ast -> ast.parse(pos))};
				macro new fure.hxx.Ast.Nodes($innerVal);
			case Code(offset, src): Context.parseInlineString(src, pos + offset);
		}
		#else
		return Context.parseInlineString(ast.dumps(), pos);
		#end
	}
	#end

	static inline function isClass(tag:String):Bool {
		var index = tag.lastIndexOf('.') + 1;
		var code = tag.charCodeAt(index);
		return 'A'.code <= code && code <= 'Z'.code;
	}
}

class Nodes {
	public final arr:Array<Any>;

	public inline function new(nodes:Array<Any>)
		this.arr = nodes.flatMap(node -> Std.isOfType(node, Array) ? (node : Array<Any>) : [node]);

	public static function flat(arr:Array<Any>):Array<Any>
		return arr.flatMap(node -> Std.isOfType(node, Nodes) ? flat((node : Nodes).arr) : [node]);
}
