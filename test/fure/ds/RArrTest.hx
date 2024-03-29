package fure.ds;

import fure.rx.Promise;
import fure.ds.RArr;
import fure.ds.RArr.RArrIterator;
import fure.test.Assert;

class RArrTest {
	public inline function new() {}

	public function test():Promise<Void> {
		var raw:Array<Dynamic> = ['A', ['B', ['C']], [], [['D'], ['E', 'F'], 'G'], 'H'];

		var arr0 = RArr.from(raw, (val:Dynamic) -> Std.isOfType(val, Array) ? Right((val : Array<Dynamic>)) : Left((val : String)));

		var arr1 = RArrIterator.toRArr([
			Left('A'),
			Right([Left('B'), Right([Left('C')])]),
			Right([]),
			Right([Right([Left('D')]), Right([Left('E'), Left('F')]), Left('G')]),
			Left('H'),
		]);

		var arr2 = new fure.ds.RArr<String>();
		arr2.push('A');
		arr2.dive();
		arr2.push('B');
		arr2.dive();
		arr2.push('C');
		arr2.rise();
		arr2.rise();
		arr2.dive();
		arr2.rise();
		arr2.dive();
		arr2.dive();
		arr2.push('D');
		arr2.rise();
		arr2.dive();
		arr2.push('E');
		arr2.push('F');
		arr2.rise();
		arr2.push('G');
		arr2.rise();
		arr2.push('H');

		var arr3 = RArrIterator.toRArr(arr2);

		Assert.all([
			assertEquals(raw, RArrIterator.deepToArray(arr0)),
			assertEquals(raw, RArrIterator.deepToArray(arr1)),
			assertEquals(raw, RArrIterator.deepToArray(arr2)),
			assertEquals(raw, RArrIterator.deepToArray(arr3)),
			assertEquals(arr0.flat(), arr1.flat()),
			assertEquals(arr0.flat(), arr2.flat()),
			assertEquals(arr0.flat(), arr3.flat()),
		]) !;

		return Promise.empty();
	}
}
