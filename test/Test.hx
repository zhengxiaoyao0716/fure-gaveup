import fure.ds.RArrTest;
import fure.HxxTest;
import fure.web.WebTest;
import fure.rx.PromiseTest;

function main() {
	new RArrTest().test();
	new HxxTest().test();
	new WebTest().test();
	new PromiseTest().test();
}
