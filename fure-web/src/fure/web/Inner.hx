package fure.web;

using Lambda;

@:using(fure.web.Inner)
typedef Inner = fure.ds.Iter.Inner;

typedef Flat = fure.ds.Iter.Flat;

function lines(inner:Inner, pad:String):Array<String>
	return inner.filter(ele -> ele != null)
		.flatMap(ele -> if (Std.isOfType(ele, Element)) (ele : Element).template() else [Std.string(ele)])
		.map(line -> pad + line);
