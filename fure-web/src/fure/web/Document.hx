package fure.web;

import fure.Hxx;
import fure.Info;
import fure.Tools;
import fure.rx.State;
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
	final lang:State<String>;
	final charset:State<String>;
	final icon:State<String>;
	final title:State<String>;
}

@:forward
private abstract OptionalProps(DocumentProps) from DocumentProps to DocumentProps {
	@:from
	public function new(props:{
		?lang:State<String>,
		?charset:State<String>,
		?icon:State<String>,
		?title:State<String>,
	}) {
		this = {
			lang: props.lang == null ? 'en' : props.lang,
			charset: props.charset == null ? 'UTF-8' : props.charset,
			icon: props.icon == null ? 'favicon.ico' : props.icon,
			title: props.title == null ? '' : props.title,
		};
	}
}

class Document extends Element {
	static final headHint = '<!-- [fure-web ${FURE_VERSION)}](${FURE_WEBSITE}) -->';
	static final bodyHint = '<noscript>You need to enable JavaScript to run this app.</noscript>';

	public final props:DocumentProps;

	var headElement:Element;
	var bodyElement:Element;

	public function new(props:OptionalProps, inner:Inner) {
		super('html', ['lang' => props.lang]);
		this.props = props;

		var bodyScope = [];
		var headScope = ['meta' => [], 'link' => []];
		for (ele in inner) {
			if (ele == null)
				continue;
			if (!Std.isOfType(ele, Element)) {
				bodyScope.push(ele);
				continue;
			}
			var ele = (ele : Element);
			var scope = Optional.ofNullable(headScope.get(ele.tag)) || bodyScope;
			scope.push(ele);
		}
		this.headElement = hxx('
		<head>
			(headHint)
			<meta charset=${props.charset} />
			<>${headScope['meta']}</>
			<link rel="shortcut icon" href=${props.icon} type="image/x-icon" />
			<>${headScope['link']}</>
			<title>(props.title)</title>
		</head>
		');
		this.bodyElement = hxx('
		<body>
			(bodyHint)
			<>bodyScope</>
		</body>
		');
	}

	public override function template():Array<String> {
		return ['<!DOCTYPE html>', '<html${Element.buildAttr(attr)}>', ''] //
			.concat(headElement.template())
			.concat([''])
			.concat(bodyElement.template())
			.concat(['', '</html>', '']);
	}

	public inline function toString():String
		return template().join('\n');
}

macro function createElement(tag:String, props:Expr, ?inner:Expr):ExprOf<Element> {
	var attr = [];
	var body = inner;

	var ptype = Context.typeof(props);
	var follow = ptype.follow();
	switch follow {
		case TAnonymous(_.get() => _.fields => fields):
			if (fields.empty())
				return macro new Element($v{tag}, null, $body);
			for (field in fields) {
				var name = field.name;
				attr.push(macro $v{name} => _.$name);
			}
		case TMono(_.get() => null):
			return macro new Element($v{tag}, null, $body);
		case _:
			if (props.getValue() == null)
				return macro new Element($v{tag}, null, $body);
			Context.error("Object type expected instead of " + ptype.toString(), props.pos);
	}
	var attr = macro {var _ = $props; [$a{attr}];};
	return macro new Element($v{tag}, $attr, $body);
}
