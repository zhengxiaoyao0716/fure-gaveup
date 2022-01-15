package fure;

#if macro
import haxe.macro.Context;

using haxe.macro.Tools;
#end

interface Router<R> {
	function routes():Array<R>;
}

#if macro
function build() {
	var fields = Context.getBuildFields();
	var routes = [];
	for (field in fields) {
		switch field.kind {
			case FFun(f):
				for (meta in field.meta) {
					if (meta.name.substr(0, 7) != ':route.')
						continue;
					var mname = meta.name.substr(7);
					var fname = field.name;
					var params = [macro @:pos(field.pos) $v{fname}, macro @:pos(field.pos) this.$fname,];
					if (meta.params != null)
						params = params.concat(meta.params);
					routes.push(macro @:pos(meta.pos) $i{mname}($a{params}));
				}
			case _:
		}
	}
	fields.push({
		name: 'routes',
		access: [APublic],
		pos: Context.currentPos(),
		kind: FFun({
			expr: macro return $a{routes},
			args: [],
		}),
	});
	return fields;
}
#end
