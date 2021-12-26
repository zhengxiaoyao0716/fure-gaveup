package fure.rx;

import fure.rx.State.Operator;
import haxe.Timer;
import fure.test.Assert;

using fure.rx.StateTest;
using Lambda;

class StateTest {
	public inline function new() {}

	public function test():Promise<Any> {
		var timeout = Promise.delay(Promise.empty, 1000);

		var state:State<Int> = 0;
		assertEquals(0, state.get());

		Promise.future(f -> {
			var count = 0;
			state.observe(value -> {
				assertEquals(2, value);
				f.setSuccess(null);
				assertEquals(1, ++count);
			});
		}).mustResolved(timeout);

		state.observe(value -> assertNever()).cancel();

		Promise.future(f -> state.pipe(v -> v * 2).observe(value -> {
			assertEquals(4, value);
			f.setSuccess(null);
		})).mustResolved(timeout);

		state.set(1); // .onSuccess(value -> assertEquals(2, value)).mustResolved(timeout);
		assertEquals(1, state.get());
		state.set(2); // .onSuccess(value -> assertEquals(2, value)).mustResolved(timeout);
		assertEquals(2, state.get());

		var s1:State<Int> = 0x0001;
		var s2:State<Int> = 0x0020;
		var s3:State<Int> = 0x0300;
		var s4:State<Int> = 0x4000;
		var sum12 = State.compute(() -> s1.get() | s2.get());
		var sum23 = State.compute(() -> s2.get() | s3.get());
		var sum34 = State.compute(() -> s3.get() | s4.get());

		assertEquals(0x0021, sum12);
		assertEquals(0x0320, sum23);
		assertEquals(0x4300, sum34);

		sum12.observe(value -> assertNever());
		Promise.future(f -> sum23.observe(value -> {
			assertEquals(0x0C20, value);
			f.setSuccess(null);
		})).mustResolved(timeout);
		Promise.future(f -> sum34.observe(value -> {
			assertEquals(0xDC00, value);
			f.setSuccess(null);
		})).mustResolved(timeout);

		s3.set(0x0C00);
		s4.set(0xD000);

		var stream:State<Int> = new State();
		var increment = Promise.future(f -> {
			function inc() {
				for (i in 0...5)
					stream.next(1 + i);
				f.setSuccess(stream.get());
			};
			Timer.delay(inc, 100);
		});
		increment.onSuccess(value -> assertEquals(value, stream.get()));

		stream.pipe(i -> i * 10).observe(value -> assertEquals(stream.get() * 10, value));
		stream.pipe(Operator.peek(i -> assertEquals(stream.get(), i)));
		stream.pipe(Operator.filter(i -> i & 1 > 0)).observe(value -> assertTrue(value & 1 > 0));
		stream.pipe(Operator.fold('', (i:Int, r:String) -> '${r}${i}')) //
			.observe(value -> assertEquals('12345'.substr(0, stream.get()), value));
		stream.pipe(Operator.sum()).observe(value -> {
			var num = stream.get();
			assertEquals([1, 2, 3, 4, 5].slice(0, num).fold((i, j) -> i + j, 0), value);
		});
		stream.pipe(Operator.push(3)).observe(value -> {
			var num = stream.get();
			var offset = num > 3 ? num - 3 : 0;
			assertEquals([1, 2, 3, 4, 5].slice(offset, num), value);
		});

		var events:State<String> = new State();
		var increment = Promise.future(f -> {
			var values = 'ABCDE';
			var index = 0;
			function inc() {
				var value = values.charAt(index++);
				events.set(value);
				if (index < 5)
					Timer.delay(inc, 100);
				else
					f.setSuccess(value);
			};
			Timer.delay(inc, 100);
		});
		increment.onSuccess(value -> assertEquals(value, events.get()));
		events.pipe(Operator.debounce(500)).observe(value -> assertEquals('E', value));
		events.pipe(Operator.throttle(500)).observe(value -> assertEquals('A', value));

		return timeout;
	}
}

private function mustResolved<T>(task:Promise<T>, timeout:Promise<Any>, ?pos:haxe.PosInfos):Promise<T>
	return task.timeout(timeout).onFailure(error -> assertNever('task not resolved, ${error.message}', pos));
