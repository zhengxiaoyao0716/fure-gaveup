package fure.hxx;

import haxe.Exception;
import fure.collection.RArr;

using StringTools;

abstract Hxx(String) from String {
	public inline function new(src:String)
		this = src;

	@:to
	public function ast():Ast {
		var builder = new RArr<AstBuilder>();
		takeNode(0, builder);
		var builder = builder.iterator();

		return switch (builder.length) {
			case 0: Code(0, 'null');
			case 1: buildAst(builder.next());
			case _: Flat(0, () -> [for (ast in builder) buildAst(ast)]);
		}
	}

	//#region translate

	function takeNode(offset:Int, builder:RArr<AstBuilder>):Int {
		var state = State.Begin;
		var offset = skipSpace(offset);

		var props:Array<String> = null;

		while (offset < this.length) {
			switch (state) {
				case Begin:
					if (this.fastCodeAt(offset) != '<'.code) {
						var endAt = takeComment(offset);
						if (endAt > offset) {
							offset = skipSpace(endAt);
							continue;
						}
						var endAt = takeBlock(offset);
						if (endAt <= offset)
							throw new HxxAstException('Expected `<`', this, offset);
						var block = this.substring(offset, endAt);

						builder.push(Code(offset, block));
						// state = Begin;
						offset = skipSpace(endAt);
						continue;
					}
					if (offset + 1 >= this.length)
						throw new HxxAstException('Missing tag', this, offset);

					switch (this.fastCodeAt(offset + 1)) {
						case '/'.code:
							if (offset + 2 >= this.length)
								throw new HxxAstException('Expected tag or `>`', this, offset);
							// builder.rize();
							return offset;
						case '>'.code:
							builder.dive(2);
							builder.push(Flat(offset));
							state = Inner;
							offset = skipSpace(offset + 2);
						default:
							var endAt = takeIdent(offset + 1);
							var tag = this.substring(offset + 1, endAt);

							builder.dive(3);
							builder.push(Node(offset, tag));

							state = Props;
							offset = skipSpace(endAt);
							props = [];
					}

				case Props:
					var charCode = this.fastCodeAt(offset);
					switch (charCode) {
						case '/'.code:
							if (props != null)
								builder.push(Code(offset, props.length <= 0 ? 'null' : '{ ${props.join(', ')} }'));

							offset = skipSpace(offset + 1);
							if (offset >= this.length)
								throw new HxxAstException('Expected `>`', this, offset);
							var char = this.fastCodeAt(offset);
							if (char != '>'.code)
								throw new HxxAstException('Expected `>`', this, offset);

							builder.dive();
							builder.rise();

							state = Begin;
							offset = skipSpace(offset + 1);

						case '>'.code:
							if (props != null)
								builder.push(Code(offset, props.length <= 0 ? 'null' : '{ ${props.join(', ')} }'));

							state = Inner;
							offset = skipSpace(offset + 1);

						default:
							if (props == null)
								throw new HxxAstException('Expected `>`', this, offset);
							var endAt = takeBlock(offset);
							if (endAt > offset) {
								var block = this.substring(offset, endAt);
	
								props = null;
								builder.push(Code(offset, block));
								// state = Props;
								offset = skipSpace(endAt);
								continue;
							}
							var endAt = takeIdent(offset);
							var name = this.substring(offset, endAt);
							offset = skipSpace(endAt);
							if (this.fastCodeAt(endAt) != '='.code)
								throw new HxxAstException('Expected `=`', this, offset);
							offset = skipSpace(offset + 1);
							var endAt = takeBlock(offset);
							if (endAt <= offset)
								throw new HxxAstException('Expected block', this, offset);
							var value = this.substring(offset, endAt);
							props.push('$name: $value');
							offset = skipSpace(endAt);
					}

				case Inner:
					builder.dive();
					state = Close;
					var endAt = takeNode(offset, builder);
					offset = skipSpace(endAt);
					builder.rise();

				case Close:
					if (offset + 1 >= this.length || this.fastCodeAt(offset) != '<'.code || this.fastCodeAt(offset + 1) != '/'.code)
						throw new HxxAstException('Expected `</`', this, offset);
					var endAt = takeIdent(offset + 2);
					offset = skipSpace(endAt);
					if (offset >= this.length || this.fastCodeAt(offset) != '>'.code)
						throw new HxxAstException('Expected `>`', this, offset);
					state = Begin;
					offset = skipSpace(offset + 1);
			}
		}

		return offset;
	}

	static inline function isSpace(c:Int) {
		// as StringTools.isSpace
		return (c > 8 && c < 14) || c == 32;
	}

	function skipSpace(offset:Int):Int {
		while (offset < this.length) {
			var charCode = this.fastCodeAt(offset);
			if (isSpace(charCode))
				offset++;
			else
				return offset;
		}
		return offset;
	}

	static inline function isIdent(c:Int) {
		if (isSpace(c))
			return false;
		if (c == '-'.code || c == '.'.code || c == '-'.code)
			return true;
		if ('0'.code <= c && c <= '9'.code)
			return true;
		if ('A'.code <= c && c <= 'Z'.code)
			return true;
		if ('a'.code <= c && c <= 'z'.code)
			return true;
		return false;
	}

	function takeIdent(offset:Int):Int {
		while (offset < this.length) {
			var charCode = this.fastCodeAt(offset);
			if (isIdent(charCode))
				offset++;
			else
				return offset;
		}
		return offset;
	}

	function takeComment(offset:Int):Int {
		if (this.charCodeAt(offset) != '/'.code)
			return offset;
		offset++;
		if (offset >= this.length)
			return offset;
		var char = this.fastCodeAt(offset);
		if (char == '/'.code) {
			while (++offset < this.length) {
				if (this.fastCodeAt(offset) == '\n'.code)
					return offset + 1;
			}
		} else if (char == '*'.code) {
			while (++offset < this.length - 1) {
				if (this.fastCodeAt(offset) == '*'.code && this.fastCodeAt(offset + 1) == '/'.code)
					return offset + 2;
			}
		} else {
			return offset - 1;
		}
		return offset;
	}

	function takeBlock(offset:Int):Int {
		var closer = [];
		var quote:Null<Int> = null;
		while (offset < this.length) {
			var endAt = takeComment(offset);
			if (endAt > offset) {
				offset = endAt;
				continue;
			}
			var charCode = this.fastCodeAt(offset);
			if (charCode == '\\'.code) {
				offset++;
				continue;
			}
			if (quote == null) {
				switch (charCode) {
					case '{'.code:
						closer.push('}'.code);
					case '['.code:
						closer.push(']'.code);
					case '('.code:
						closer.push(')'.code);
					case "'".code:
						quote = charCode;
					case '"'.code:
						quote = charCode;
					default:
						if (closer.length <= 0)
							return offset;
						if (charCode == closer[closer.length - 1])
							closer.pop();
				}
			} else if (quote == charCode) {
				quote = null;
			}
			offset++;
			if (closer.length <= 0 && quote == null)
				return offset;
		}
		return offset;
	}
	//#endregion

	static function buildAst(nodes:Or<AstBuilder, RArrIterable<AstBuilder>>):Ast {
		return switch (nodes) {
			case A(one):
				switch (one) {
					case Code(offset, src): Code(offset, src);
					case _: null; // never
				}
			case B(_.iterator() => nodes):
				switch (nodes.next()) {
					case A(one):
						switch (one) {
							case Node(offset, tag):
								var props = nodes.next();
								var inner = switch (nodes.next()) {
									case A(_): null;
									case B(_.iterator() => inner): inner;
								}
								Node(offset, tag, () -> buildAst(props), () -> [for (ast in inner) buildAst(ast)]);
							case Flat(offset):
								var inner = switch (nodes.next()) {
									case A(_): null;
									case B(_.iterator() => inner): inner;
								}
								Flat(offset, () -> [for (ast in inner) buildAst(ast)]);
							case _: null; // never
						}
					case _: null; // never
				}
		}
	}
}

enum abstract State(Int) {
	var Begin;
	var Props;
	var Inner;
	var Close;
}

class HxxAstException extends Exception {
	public var src:String;
	public var offset:Int;
	public var lineAt:Int;
	public var charAt:Int;

	public function new(message:String, src:String, offset:Int) {
		super(message);
		this.src = src;
		this.offset = offset;

		lineAt = 1;
		charAt = 0;
		for (i in 0...offset) {
			var c = src.fastCodeAt(i);
			if (c == '\n'.code) {
				lineAt++;
				charAt = 0;
			} else if (c != '\r'.code) {
				charAt++;
			}
		}
	}

	public override inline function toString():String {
		return Type.getClassName(Type.getClass(this)) + ": " + message + " at line " + lineAt + " char " + charAt;
	}
}

enum AstBuilder {
	Node(offset:Int, tag:String);
	Flat(offset:Int);
	Code(offset:Int, src:String);
}
