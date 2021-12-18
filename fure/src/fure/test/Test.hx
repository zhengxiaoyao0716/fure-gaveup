package fure.test;

import fure.log.Logger;
import haxe.Exception;
import haxe.Timer;
import fure.rx.Promise;
#if target.threaded
import sys.thread.*;
#end

#if target.threaded
private final pool = new ElasticThreadPool(16);
#end

class Test {
	public static function run(tasks:Array<() -> Promise<Any>>, timeout = 60 * 1000):Void {
		#if target.threaded
		var mutex = new Mutex();
		var promise = Promise.all([
			for (task in tasks)
				Promise.future(future -> pool.run(() -> {
					Thread.runWithEventLoop(() -> Promise.invoke(task) //
						.onComplete(status -> {
							mutex.acquire();
							future.setComplete(status);
							mutex.release();
						}));
				}))
		]);
		#else
		var promise = Promise.all([for (task in tasks) Promise.invoke(task)]);
		#end

		switch promise.status {
			case Rejected(error):
				throw error;
			#if target.threaded
			case Pending(_):
				waitPromiseComplete(promise, Timer.stamp() + timeout / 1000);
				pool.shutdown();
			#end
			case _:
				null;
		};
		var logger:Logger = {name: 'TEST'}
		logger.bingo('finished');
	}
}

#if target.threaded
function waitPromiseComplete<V>(promise:Promise<V>, timeoutAt:Float) {
	var lock = new Lock();
	promise.onComplete(_ -> lock.release());

	while (true) {
		lock.wait(timeoutAt - Timer.stamp());
		switch promise.status {
			case Rejected(error):
				throw error;
			case Resolved(_):
				return;
			case Pending(_):
				var now = Timer.stamp();
				if (now >= timeoutAt)
					throw new Exception('wait promise timeout');
		}
	}
}
#end
