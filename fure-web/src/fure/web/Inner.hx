package fure.web;

using Lambda;

@:using(fure.web.Inner)
typedef Inner = fure.hxx.Inner;

function lines(inner:Inner, pad:String):Array<String>
	return inner.filter(ele -> ele != null)
		.flatMap(ele -> if (Std.isOfType(ele, Element)) (ele : Element).template() else [Std.string(ele)])
		.map(line -> pad + line);
