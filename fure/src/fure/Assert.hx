package fure;

import haxe.Exception;
#if macro
import haxe.macro.Expr;

using haxe.macro.Tools;
#end

abstract Assert(String) from String to String {
	public inline function new(result:String)
		this = result;

	public inline function ok():Bool
		return this == '' || throw new AssertException(this);

	public static function allOk(asserts:Iterable<Assert>):Bool {
		var exception = null;
		for (assert in asserts) {
			if (assert == '')
				continue;
			// https://haxe.org/manual/expression-try-catch.html#chaining-exceptions
			// chaining not works?
			exception = new AssertException(assert, exception);
		}
		return exception == null || throw exception;
	}

	@:noUsing
	public static function value<V>(expected:V, desc:String, value:V):Assert {
		return Tools.equlas(expected, value) ? '' : '$desc should be $expected, actrual: $value';
	}

	@:noUsing
	public static function equals<V>(desc1:String, value1:V, desc2:String, value2:V):Assert {
		return Tools.equlas(value1, value2) ? '' : '$desc2 should equals $desc1, expected: $value1, actrual: $value2';
	}
}

macro function assertValue(expected:Expr, actual:Expr):Expr
	return macro fure.Assert.value($expected, $v{actual.toString()}, $actual);

macro function assertEquals<V>(expected:Expr, actual:Expr):Expr
	return macro fure.Assert.equals($v{expected.toString()}, $expected, $v{actual.toString()}, $actual);

class AssertException extends Exception {
	public var src:String;

	public function new(message:String, ?previous:AssertException)
		super(message, previous);

	public override inline function toString():String
		return 'Assert failed: $message';
}
