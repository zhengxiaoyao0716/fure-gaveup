package web;

import fure.web.Document;
import fure.Macro.hxx;

class Web {
	public function new() {}

	@:page('index.html')
	public function index() {
		var user = {
			name: 'user#test',
			avatar: './avatar.png',
			intro: 'some intro',
			email: 'test@test.com',
		};
		return hxx('
			<Document charset="UTF-8" title="Hello Fure-Web">
				<Profile (user)/>
			</Document>
		');
	}
}

#if js
@WebComponent // generate tagName
class Profile extends js.html.HtmlElement {
	final template = inner -> '<template>
		<p class="name"></p>
		<img src="" class="avatar">
		<p class="intro">${inner[0]}</p>
		<a class="email" href="mailto:"></a>
		${inner[1]} // compile to slots
	</template>';

	public function new(props:{}, inner:Array<Any>) {
		super();
		var template = new js.html.TemplateElement().content;
		var shadowRoot = this.attachShadow({mode: js.html.ShadowRootMode.OPEN});
		shadowRoot.appendChild(template.cloneNode(true));
	}
}
#end
