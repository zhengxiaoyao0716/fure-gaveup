package fure.test;

import fure.log.Logger;
import haxe.ds.GenericStack;
import haxe.PosInfos;
import haxe.Exception;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.Tools;
#end
using fure.Tools;
using Lambda;

macro function assertTrue(actual:Expr):ExprOf<Assert>
	return macro @:pos(Context.currentPos())
		Assert.value(true, $v{actual.toString()}, () -> $actual);

macro function assertValue(expected:Expr, actual:Expr):ExprOf<Assert>
	return macro @:pos(Context.currentPos())
		Assert.value($expected, $v{actual.toString()}, () -> $actual);

macro function assertEquals<V>(expected:Expr, actual:Expr):ExprOf<Assert>
	return macro @:pos(Context.currentPos())
		Assert.equals($v{expected.toString()}, () -> $expected, $v{actual.toString()}, () -> $actual);

inline function assertNever(?msg:String, ?pos:PosInfos)
	return Assert.never(msg == null ? 'the line should never reached' : msg, pos);

typedef Error = {?msg:String, ?pos:PosInfos};

@:forward(isEmpty, iterator)
abstract Assert(GenericStack<Error>) from GenericStack<Error> to GenericStack<Error> {
	@:from
	public static function ofError(error:Error):Assert {
		var logger = Logger.easy({name: 'TEST'});
		var stack = new GenericStack<Error>();
		if (error.msg != null) {
			stack.add(error);
			logger.error(error.msg, error.pos);
		}
		return stack;
	}

	private static macro function ofExpr(predicate:Expr, message:Expr):ExprOf<Assert>
		return macro $predicate ? {pos: pos} : {msg: $message, pos: pos};

	public function add(assert:Assert)
		for (error in assert)
			this.add(error);

	public inline function count(?pred:(item:Error) -> Bool)
		return this.count(pred);

	public inline function ok():Bool
		return this.isEmpty();

	@:op(A!)
	public function mustOk():Assert {
		if (ok())
			return this;
		var total = 0, failed = 0;
		for (error in this) {
			total++;
			if (error.msg != null)
				failed++;
		}
		throw new Exception('asserted $total cases, $failed failed');
	}

	public static function all(asserts:Iterable<Assert>):Assert {
		var assetAll:Assert = new GenericStack<Error>();
		for (assert in asserts)
			assetAll.add(assert);
		return assetAll;
	}

	@:noUsing
	public static function value<V>(expected:V, desc:String, value:() -> V, ?pos:PosInfos):Assert {
		var value = tryCatch(desc, value());
		return ofExpr(Tools.equals(expected, value), '$desc should be $expected, actrual: $value');
	}

	@:noUsing
	public static function equals<V>(desc1:String, value1:() -> V, desc2:String, value2:() -> V, ?pos:PosInfos):Assert {
		var value1 = tryCatch(desc1, value1());
		var value2 = tryCatch(desc2, value2());
		return ofExpr(Tools.equals(value1, value2), '$desc2 should equals $desc1, expected: $value1, actrual: $value2');
	}

	@:noUsing
	public static function never(msg:String, ?pos:PosInfos):Assert
		return {msg: msg, pos: pos}
}

private macro function tryCatch<V>(desc:ExprOf<String>, expr:Expr):Expr {
	return macro try {
		$expr;
	} catch (e) {
		return {msg: 'execute ' + $desc + ' failed, reason: ' + e, pos: pos};
	};
}
