package fure.rx;

import haxe.Exception;
import fure.log.Assert;
import fure.rx.Promise;
#if macro
import haxe.macro.Context;
#end

class PromiseTest {
	private static final exception = new Exception('test raise exception');

	public inline function new() {}

	public function test():Promise<Void> {
		var promise:Promise<Int> = future -> {};
		assertTrue(promise.status.match(Pending(_)));

		switch promise.status {
			case Pending(raise):
				raise(exception);
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
			assertEquals(1, p1.status.value());
			assertEquals(2, p2.status.value());
			assertEquals([1, 2], status.value());
		});
		Promise.any([p1, p2]).onComplete(assertStatus(Resolved(1)));

		var reject = Promise.reject(exception);
		Promise.all([reject, p1]).onComplete(assertStatus(Rejected(exception)));
		Promise.any([reject]).onComplete(status -> assertTrue(status.match(Rejected(_))));
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

	private static macro function assertStatus<V>(value:ExprOf<Status<V>>):ExprOf<Assert>
		return macro @:pos(Context.currentPos()) _ -> assertEquals($value, _);
}
