function Blabber(w = display_get_gui_width()) constructor {
	width = w;

	time = 0;
	dialogs = [];

	static step = function() {
		time += (delta_time / 1000);
	}
}

enum BLABBER { TYPE, TEXT, NEW_LINE };
enum BLABBER_TEXT { TYPE, TEXT, FONT, COLOR, ALPHA, WIDTH, HEIGHT };

function Chatter() constructor {
	
}