package fure.web;

import fure.rx.State;

using Lambda;

@:using(fure.web.Inner)
typedef Inner = fure.ds.Iter.Inner;

typedef Flat = fure.ds.Iter.Flat;

function lines(inner:Inner, pad:String):Array<String>
	return inner.filter(ele -> ele != null).flatMap(renderInnerElement).map(line -> pad + line);

function renderInnerElement(ele:Any):Array<String> {
	if (Std.isOfType(ele, Element))
		return (ele : Element).template();
	if (Std.isOfType(ele, Observable))
		return renderInnerElement((ele : Observable<Any>).get());
	return [Std.string(ele)];
}
