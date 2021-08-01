package fure.web;

typedef Props = {
	charset:String,
	title:String,
};

class Document {
	public var title(default, set):String;

	public function new(props:Props, inner:Array<Any>) {
		this.title = props.title;
		// TODO
	}

	private function set_title(title:String):String {
		this.title = title;
		// TODO document.querySelector('title').title = title;
		return title;
	}
}
