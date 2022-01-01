package fure.rx;

import fure.web.Inner.lines;
import haxe.ds.Option;
import fure.rx.Promise.PromiseLike;

@:forward
abstract Operator<T, R>({pipe:Observable<T>->Observable<R>}) {
	public inline function new(pipe:Observable<T>->Observable<R>)
		this = {pipe: pipe};

	public static function fork<T, R>(present:T->Option<R>, ?absent:() -> Option<R>):Operator<T, R> {
		return new Operator(origin -> switch origin.value {
			case Some(v): new Observable(present(v));
			case None: new Observable(absent == null ? None : absent());
		});
	}

	@:from // flow = map & debounce(0)
	public static function flow<T, R>(mapper:T->R):Operator<T, R> {
		return new Operator(origin -> {
			var observable = origin.pipe(fork(v -> Some(mapper(v))));
			origin.observe(value -> observable.set(mapper(value)));
			return observable;
		});
	}

	public static function map<T, R>(mapper:T->R):Operator<T, R> {
		return new Operator(origin -> {
			var observable = origin.pipe(fork(v -> Some(mapper(v))));
			origin.observe(value -> observable.next(mapper(value)));
			return observable;
		});
	}

	public static function peek<T>(observer:T->Void):Operator<T, T> {
		return inline map(v -> {
			observer(v);
			return v;
		});
	}

	public static function filter<T>(predicate:T->Bool):Operator<T, T> {
		return new Operator(origin -> {
			var observable = origin.pipe(fork(value -> predicate(value) ? Some(value) : None));
			origin.observe(value -> {
				if (predicate(value))
					observable.next(value);
			});
			return observable;
		});
	}

	public static function debounceTime<T>(delay:Int):Operator<T, T>
		return inline debounce(v -> Promise.delay(Promise.empty, delay));

	public static function debounce<T>(delay:T->PromiseLike<Any>):Operator<T, T> {
		return new Operator(origin -> {
			var timer:Null<PromiseLike<Any>> = null;
			var observable = new Observable(None);
			function update(value) {
				if (timer == null) {
					timer = delay(value);
					timer.then(_status -> {
						timer = null;
						observable.next(origin.get());
						return Promise.empty();
					});
				}
			}
			switch (origin.value) {
				case Some(v): update(v);
				case None:
			}
			origin.observe(update);
			return observable;
		});
	}

	public static function throttleTime<T>(duration:Int):Operator<T, T>
		return inline throttle(v -> Promise.delay(Promise.empty, duration));

	public static function throttle<T>(duration:T->PromiseLike<Any>):Operator<T, T> {
		return new Operator(origin -> {
			var timer:Null<PromiseLike<Any>> = null;
			var observable = new Observable(None);
			function update(value) {
				if (timer == null) {
					observable.next(value);
					timer = duration(value);
					timer.then(_status -> {
						timer = null;
						return Promise.empty();
					});
				}
			}
			switch (origin.value) {
				case Some(v): update(v);
				case None:
			}
			origin.observe(update);
			return observable;
		});
	}

	public static function sample<T>(periodic:Observable<Any>):Operator<T, T> {
		return new Operator(origin -> {
			var value = origin.value;
			origin.observe(_v -> value = origin.value);
			var observable = new Observable(None);
			periodic.observe(_v -> {
				switch value {
					case Some(v):
						value = None;
						observable.next(v);
					case None:
				}
			});
			return observable;
		});
	}

	public static function fold<T, R>(init:R, acc:(T, R) -> R):Operator<T, R> {
		return new Operator(origin -> {
			var observable = new Observable(switch origin.value {
				case Some(v): Some(acc(v, init));
				case None: Some(init);
			});
			origin.observe(value -> observable.next(acc(value, observable.get())));
			return observable;
		});
	}

	public static macro function sum<T>():ExprOf<Operator<T, T>> {
		return macro new fure.rx.Operator(origin -> {
			var observable = origin.pipe(fork(v -> Some(v), () -> Some(0)));
			origin.observe(value -> observable.next(value + observable.get()));
			return observable;
		});
	}

	public static function join(sep = ''):Operator<String, String> {
		return new Operator(origin -> {
			var observable = origin.pipe(fork(v -> Some(v)));
			origin.observe(value -> switch observable.value {
				case Some(v): observable.next(v + sep + value);
				case None: observable.next(value);
			});
			return observable;
		});
	}

	// (1, 2, 3, ...) => ([1], [1, 2], [1, 2, 3], ...)
	public static function push<T>(maxSize = -1):Operator<T, Array<T>> {
		return new Operator(origin -> {
			var observable = origin.pipe(fork(v -> Some([v]), () -> Some([])));
			origin.observe(value -> {
				var arr = observable.get();
				arr.push(value);
				if (maxSize > 0) {
					var out = arr.length - maxSize;
					if (out > 0) {
						observable.next(arr.slice(out));
						return;
					}
				}
				observable.next(arr);
			});
			return observable;
		});
	}
}
