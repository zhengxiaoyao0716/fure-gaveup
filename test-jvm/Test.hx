typedef Typedef1<V> = {function next():V;};
typedef Typedef2<V> = {function next():V;};

class Test {
	public static function main() {
		var obj:Typedef2<String> = {next: () -> "test typedef with generic and `next` function"};
		test(cast(obj:Typedef1<String>)); // `jvm` target not works?
	}

	static function test<T>(obj:Typedef1<T>) {
		trace("[SUCCEED] " + obj.next());
	}
}
