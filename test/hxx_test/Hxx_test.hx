package hxx_test;

import fure.Macro.hxx;

class Hxx_test {
    public static function test() {
		var obj = hxx(
			<Test 'root'>
				// comments
				<hxx_test.Test ['children'] />
				/* comments */
				{ hxx(<Test {msg: 'nested'}/>); }
				<AbsTest name='test inner'>
					[ hxx(<Test msg='array' />) ]
					<>
						<Test msg='flat'/>
						[ for (i in 0...Math.ceil(Math.random())) hxx(<Test key=(i) msg='flat' />) ]
					</>
					'qwe' [] {} (123)
				</AbsTest>
				<Test.test ('test function')/>
			</Test>
		);
		trace('obj: $obj');
	}
}

abstract AbsTest(Any) {
	public function new(props:{name:String}, inner:Array<Any>) {
		this = props.name;
		trace(this + ': ' + inner);
	}
}

class Test {
	public function new(props:Any, inner:Array<Any>) {
		trace(props);
	}

	public static function test(props:Any, inner:Array<Any>):Any {
		trace(props);
		return null;
	}
}
