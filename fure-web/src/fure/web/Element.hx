package fure.web;

#if macro
import haxe.macro.Expr;
#end

using StringTools;
using fure.Tools;

typedef Attr = Null<Map<String, Any>>;
typedef Body = Null<Inner>;

class Element {
	public final tag:String;

	var attr(get, default):Attr;
	var body(get, default):Body;

	function get_attr():Attr
		return this.attr;

	function get_body():Body
		return this.body;

	public function new(tag:String, ?attr:Map<String, Any>, ?body:Inner) {
		this.tag = tag;
		this.attr = attr;
		this.body = body;
	}

	public function template():Array<String> {
		var attr = Optional.ofNullable(this.attr) && buildAttr || '';
		var body:Inner = Optional.ofNullable(this.body) || [];
		if (body.isEmpty())
			return ['<$tag$attr />'];
		var lines = body.lines('  ');
		if (lines.length == 1)
			return ['<$tag$attr>${lines[0].substr(2)}</$tag>'];
		lines.insert(0, '<$tag$attr>');
		lines.push('</$tag>');
		return lines;
	}

	public macro inline function hxx(self:Expr, expr:Expr):Expr
		return macro Document.hxx($expr);
}

typedef VarArgs<T> = fure.ds.Iter.VarArgs<T>;

abstract Elements<T>(Inner.Flat) {
	public function new(tag:String, args:VarArgs<T>, attr:T->Attr, body:T->Body) {
		this = new Inner.Flat([]);
		for (arg in args)
			this.push(new Element(tag, attr(arg), body(arg)));
	}
}

function buildAttr(attr:Attr):String {
	var attr = attr.keyValueIterable().map(kv -> {
		var key = kv.key.fastCodeAt(0) == '_'.code ? kv.key.substr(1) : kv.key;
		var key = switch key {
			case "classList": "class";
			case _ => key: key;
		}
		var value = Std.isOfType(kv.value, Array) ? (kv.value : Array<Any>).join(' ') : (kv.value : String);
		return ' ${key}="${value}"';
	});
	attr.sort((s1, s2) -> s1 < s2 ? -1 : s1 == s2 ? 0 : 1);
	return attr.join('');
}
