import fure.ds.RArrTest;
import fure.HxxTest;
import fure.web.WebTest;
import fure.rx.PromiseTest;
import fure.test.Test;

function main() {
	Test.run([
		new RArrTest().test,
		new HxxTest().test,
		new WebTest().test,
		new PromiseTest().test,
	]);
}
