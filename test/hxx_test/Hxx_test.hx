package hxx_test;

import fure.hxx.Ast.Nodes;
import fure.Assert.assertEquals;
import fure.Macro.hxx;


class Hxx_test {
	public static function test() {
		var hxxFormatObj = hxx(
			<Test 'root'>
				// comments
				<hxx_test.Test ['children'] />
				/* comments */
				{ hxx(<Test {msg: 'nested'}/>); }
				<Test.test ('test function')/>
				<AbsTest name='test inner'>
					[ hxx(<Test msg='array' />) ]
					<>
						<Test msg='flat'/>
						[ for (i in 0...2) hxx(<Test key=(i) msg='flat' />) ]
					</>
					<Test.flat>
						<Test msg='custom flat'/>
					</Test.flat>
					'qwe' [] {} (123)
				</AbsTest>
			</Test>
		);

		var normalObj = new Test('root', [
			new hxx_test.Test(['children'], []),
			new Test({msg: 'nested'}, []),
			Test.test(('test function'), []),
			new AbsTest({name: 'test inner'}, [
				[new Test({msg: 'array'}, [])],
				new Test({msg: 'flat'}, []),
				new Test({key: 0, msg: 'flat'}, []),
				new Test({key: 1, msg: 'flat'}, []),
				new Test({msg: 'custom flat'}, []),
				'qwe', [], {}, (123),
			]),
		]);

		assertEquals(normalObj.toString(), hxxFormatObj.toString()).ok();
	}
}

abstract AbsTest(Any) {
	public function new(props:{name:String}, inner:Array<Any>) {
		var innerText = inner.map(Std.string).join(', ');
		this = 'new AbsTest(${props}, [$innerText])';
	}
}

class Test {
	final props:Any;
	final inner:Array<Any>;

	public function new(props:Any, inner:Array<Any>) {
		this.props = props;
		this.inner = inner;
	}

	public static function test(props:Any, inner:Array<Any>):Any {
		return props;
	}

	public static function flat(props:Any, inner:Array<Any>): Nodes {
		return new Nodes(inner);
	}

	public function toString():String {
		var innerText = this.inner.map(Std.string).join(', ');
		return 'new Test(${this.props}, [$innerText])';
	}
}
