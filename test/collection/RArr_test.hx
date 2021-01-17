package collection;

import fure.collection.RArr;
import fure.collection.RArr.RArrIterator;

class RArr_test {
	public static function test() {
		var raw:Array<Dynamic> = [0, [1, [2]], [], 3, [[4], 5], 6];
		var arr0 = RArr.from(raw, (val:Dynamic) -> Std.isOfType(val, Array) ? Right((val : Array<Dynamic>)) : Left((val : Int)));
		trace(arr0.flat());
		trace(arr0.length);

		var arr1 = RArrIterator.toRArr([
			Left(0),
			Right([Left(1), Right([Left(2)])]),
			Right([]),
			Left(3),
			Right([Right([Left(4)]), Left(5)]),
			Left(6)
		]);
		trace(arr1.flat());
		trace(arr1.length);

		var arr2 = new fure.collection.RArr<Int>();
		arr2.push(0);
		arr2.dive();
		arr2.push(1);
		arr2.dive();
		arr2.push(2);
		arr2.rise();
		arr2.rise();
		arr2.dive();
		arr2.rise();
		arr2.push(3);
		arr2.dive();
		arr2.dive();
		arr2.push(4);
		arr2.rise();
		arr2.push(5);
		arr2.rise();
		arr2.push(6);
		trace(arr2.flat());
		trace(arr2.length);

		var arr3 = RArrIterator.toRArr(arr2);
		trace(arr3.flat());
		trace(arr3.length);
	}
}
