package fure.rx;

import haxe.Timer;
import haxe.Exception;
import fure.rx.Promise;
import fure.test.Assert;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class PromiseTest {
	private static final exception = new Exception('test reject exception');

	public inline function new() {}

	public function testBase():Promise<Void> {
		var promise:Promise<Int> = future -> {};
		assertTrue(promise.status.match(Pending(_)));

		switch promise.status {
			case Pending(reject):
				reject(exception);
			case _:
				assertNever();
		}
		promise.then(status -> {
			assertEquals(exception, promise.status.error());
			return Promise.empty();
		});

		promise.onSuccessThen(value -> assertNever('`onSuccessThen` reached unexpectedly'));
		promise.onFailureThen(error -> 0) //
			.onComplete(assertStatus(Resolved(0)));
		promise.onFailureThen(error -> Promise.reject(error)) //
			.onComplete(assertStatus(Rejected(exception)));
		promise.onCompleteThen(status -> 0) //
			.onComplete(assertStatus(Resolved(0)));
		promise.onCompleteThen(status -> Promise.reject(exception)) //
			.onComplete(assertStatus(Rejected(exception)));

		promise.onSuccess(value -> assertNever('`onSuccess` reached unexpectedly'));
		promise.onFailure(error -> {}) //
			.onComplete(assertStatus(Resolved(null)));
		promise.onFailure(error -> throw exception) //
			.onComplete(assertStatus(Rejected(exception)));
		promise.onComplete(status -> {}) //
			.onComplete(assertStatus(Resolved(null)));
		promise.onCompleteThen(status -> throw exception) //
			.onComplete(assertStatus(Rejected(exception)));

		var promise:Promise<Int> = 0;

		promise.onFailureThen(error -> assertNever('`onFailureThen` reached unexpectedly').count());
		promise.onSuccessThen(value -> 1 + value) //
			.onComplete(assertStatus(Resolved(1)));
		promise.onSuccessThen(value -> Promise.reject(exception)) //
			.onComplete(assertStatus(Rejected(exception)));
		promise.onCompleteThen(status -> status.value() + 1) //
			.onComplete(assertStatus(Resolved(1)));
		promise.onCompleteThen(status -> Promise.reject(exception)) //
			.onComplete(assertStatus(Rejected(exception)));

		promise.onFailure(error -> assertNever('`onFailure` reached unexpectedly'));
		promise.onSuccess(value -> {}) //
			.onComplete(assertStatus(Resolved(null)));
		promise.onSuccess(value -> throw exception) //
			.onComplete(assertStatus(Rejected(exception)));
		promise.onComplete(status -> {}) //
			.onComplete(assertStatus(Resolved(null)));
		promise.onCompleteThen(status -> throw exception) //
			.onComplete(assertStatus(Rejected(exception)));

		var p1:Promise<Int> = 1, p2:Promise<Int> = 2;
		Promise.all([p1, p2]).onComplete(status -> {
			assertMatch(Resolved(1), p1.status);
			assertMatch(Resolved(2), p2.status);
			assertMatch(Resolved([1, 2]), status);
		});
		Promise.any([p1, p2]).onComplete(assertStatus(Resolved(1)));

		var reject = Promise.reject(exception);
		Promise.all([reject, p1]).onComplete(assertStatus(Rejected(exception)));
		Promise.any([reject]).onComplete(assertStatus(Rejected(_)));
		Promise.any([reject, p1]).onComplete(assertStatus(Resolved(1)));

		var f1 = new Future();
		var f2 = new Future();
		Promise.all(([p1, f1, f2] : Dynamic)).onComplete(status -> assertEquals(([1, 'a', 'b'] : Dynamic), status.value()));
		Promise.any([f1, f2]).onComplete(assertStatus(Resolved('a')));
		f1.setSuccess('a');
		f2.setSuccess('b');

		return Promise.empty() //
			.onSuccess(value -> assertEquals(value, null)) //
			.onFailure(error -> assertNever() !) //
			;
	}

	public function testTimer():Promise<Any> {
		var t1 = Promise.delay(() -> 'tick1', 1);
		var t2 = t1.onSuccessThen(_ -> Promise.delay(() -> 'tick2', 1));
		var t3 = t2.onSuccessThen(_ -> Promise.delay(() -> 'tick3', 1));
		var t9 = t3.onSuccessThen(_ -> Promise.delay(() -> 'tick9', 6));
		assertMatch(Pending(_), t1.status);
		t1.onComplete(_ -> assertMatch(Resolved(_), t1.status)) //
			.onComplete(_ -> assertMatch(Pending(_), t2.status));
		t2.onComplete(_ -> assertMatch(Resolved(_), t2.status)) //
			.onComplete(_ -> assertMatch(Pending(_), t3.status));
		t3.onComplete(_ -> assertMatch(Resolved(_), t3.status)) //
			.onComplete(_ -> assertMatch(Pending(_), t9.status));

		var f1 = new Future();
		var f2 = new Future();
		f1.timeout(t2) // (t0: pending) -> (t1: setSuccess) -> (t2: resolve)
			.onComplete(assertStatus(Resolved('f1')));
		Promise.any([f1, t2]).onComplete(status -> {
			assertMatch(Resolved('f1'), f1.status);
			assertMatch(Pending(_), t2.status);
		});
		f2.timeout(t2) // (t0: pending) -> (t2: timeout) -> (t3: setSuccess)
			.onComplete(assertStatus(Rejected(_)));
		Promise.any([f2, t2]).onComplete(status -> {
			assertMatch(Pending(_), f2.status);
			assertMatch(Resolved('tick2'), t2.status);
		});
		t1.onSuccess(_ -> f1.setSuccess('f1'));
		t3.onSuccess(_ -> f2.setSuccess('f2'));

		return t9;
	}

	private static macro function assertStatus<V>(value:Expr):ExprOf<Assert>
		return macro @:pos(Context.currentPos()) status -> assertMatch($value, status);
}
