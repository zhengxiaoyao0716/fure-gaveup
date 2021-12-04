package fure.web;

import fure.hxx.Inner.Flat;
#if macro
import haxe.macro.Expr;
#end

using Lambda;
using StringTools;
using fure.Tools;

class Element {
	public final tag:String;
	public final attr:String;
	public final inner:Inner;

	public function new(tag:String, ?attrs:Map<String, Any>, ?inner:Inner) {
		this.tag = tag;
		this.attr = (attrs == null || attrs.empty()) ? '' : buildAttr(attrs);
		this.inner = inner.orElse([]);
	}

	public function template():Array<String> {
		if (inner.empty())
			return ['<$tag$attr />'];
		var lines = inner.lines('  ');
		if (lines.length == 1)
			return ['<$tag$attr>${lines[0].substr(2)}</$tag>'];
		lines.insert(0, '<$tag$attr>');
		lines.push('</$tag>');
		return lines;
	}

	public macro inline function hxx(self:Expr, expr:Expr):Expr
		return macro Document.hxx($expr);
}

abstract Elements(Flat) {
	@:from
	public inline function new(arr:Array<Element>)
		this = new Flat(arr);
}

function buildAttr(attrs:Map<String, Any>):String {
	return attrs.keyValueIterable().map(kv -> {
		var key = kv.key.fastCodeAt(0) == '_'.code ? kv.key.substr(1) : kv.key;
		var key = switch (key) {
			case "classList": "class";
			case _ => key: key;
		}
		var value = Std.isOfType(kv.value, Array) ? (kv.value : Array<Any>).join(' ') : (kv.value : String);
		return ' ${key}="${value}"';
	}).join('');
}
