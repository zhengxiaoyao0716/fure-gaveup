package fure.web;

import fure.Hxx;
import fure.Info;
import fure.Tools;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
#end
using Lambda;
using StringTools;

final HXX_CREATOR = Optional.ofNullable(#if macro Context #else Tools #end.definedValue('FURE_WEB_HXX_CRT')) || 'Document.createElement';

macro inline function hxx(expr:Expr):Expr
	return Hxx.parse(expr, HXX_CREATOR);

typedef DocumentProps = {
	?lang:String,
	?charset:String,
	?icon:String,
	title:String,
};

class Document extends Element {
	static final headHint = '<!-- [fure-web ${FURE_VERSION)}](${FURE_WEBSITE}) -->';
	static final bodyHint = '<noscript>You need to enable JavaScript to run this app.</noscript>';

	final props:DocumentProps;
	final inner:Inner;

	public function new(props:DocumentProps, inner:Inner) {
		super('html');
		this.props = props;
		this.inner = inner;
	}

	public override function template():Array<String> {
		var body = [];
		var head = ['meta' => [], 'link' => []];
		for (ele in inner) {
			if (ele == null)
				continue;
			if (!Std.isOfType(ele, Element)) {
				body.push(ele);
				continue;
			}
			var ele = (ele : Element);
			var scope = Optional.ofNullable(head.get(ele.tag)) || body;
			scope.push(ele);
		}
		var head = hxx('
		<head>
			(headHint)
			<meta charset=${Optional.ofNullable(props.charset).or('UTF-8')} />
			<>${head['meta']}</>
			<link rel="shortcut icon" href=${Optional.ofNullable(props.icon).or('favicon.ico')} type="image/x-icon" />
			<>${head['link']}</>
			<title>(props.title)</title>
		</head>
		');
		var body = hxx('
		<body>
			(bodyHint)
			<>body</>
		</body>
		');

		return [
			'<!DOCTYPE html>',
			'<html lang="${Optional.ofNullable(props.lang).or('en')}">',
			''
		].concat(head.template()).concat(['']).concat(body.template()).concat(['', '</html>', '']);
	}

	public inline function toString():String
		return template().join('\n');
}

macro function createElement(tag:String, props:Expr, ?inner:Expr):ExprOf<Element> {
	var block = [];
	var ptype = Context.typeof(props);
	var follow = ptype.follow();
	switch follow {
		case TAnonymous(_.get() => _.fields => fields):
			if (fields.empty())
				return macro new Element($v{tag}, null, $inner);
			for (field in fields) {
				var name = field.name;
				block.push(macro $v{name} => _.$name);
			}
		case TMono(_.get() => null):
			return macro new Element($v{tag}, null, $inner);
		case _:
			if (props.getValue() == null)
				return macro new Element($v{tag}, null, $inner);
			Context.error("Object type expected instead of " + ptype.toString(), props.pos);
	}
	return macro new Element($v{tag}, {var _ = $props; [$a{block}];}, $inner);
}
