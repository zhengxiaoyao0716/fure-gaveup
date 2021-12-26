import fure.ds.RArrTest;
import fure.HxxTest;
import fure.web.WebTest;
import fure.rx.PromiseTest;
import fure.rx.StateTest;
import fure.test.Test;

function main() {
	var promiseTest = new PromiseTest();
	Test.run([
		new RArrTest().test,
		new HxxTest().test,
		new WebTest().test,
		promiseTest.testBase,
		promiseTest.testTimer,
		new StateTest().test,
	]);
}
