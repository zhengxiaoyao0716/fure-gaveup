package collection;

import fure.collection.RArr;
import fure.collection.RArr.RArrIterator;

class RArr_test {
	public static function test() {
		var raw:Array<Dynamic> = [0, [1, [2]], [], 3, [[4], 5], 6];
		var arr0 = RArr.from(raw, (val:Dynamic) -> Std.isOfType(val, Array) ? Or.B((val : Array<Dynamic>)) : Or.A((val : Int)));
		trace(arr0.flat());
		trace(arr0.length);

		var arr1 = RArrIterator.toRArr([A(0), B([A(1), B([A(2)])]), B([]), A(3), B([B([A(4)]), A(5)]), A(6)]);
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
