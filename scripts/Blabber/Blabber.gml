globalvar FALLBACK_FONT, DIALOG_SYSTEM_FORMAT, DIALOG_FONT_CACHE;

vertex_format_begin();
vertex_format_add_position();
vertex_format_add_color();
vertex_format_add_texcoord();

DIALOG_SYSTEM_FORMAT = vertex_format_end();
DIALOG_FONT_CACHE = [];

FALLBACK_FONT = fntAriel;

function Dialog(w = display_get_gui_width(), h = display_get_gui_height() / 5) constructor {
	dialogs = [];
	
	width = w;
	height = h;
	
	index = 0;
	time = 0;
	length = 0;
	
	cursor = {
		x: 0,
		y: 0,
		previous: {
			x: 0,
			y: 0,
		}
	}
	
	line = {
		width: 0,
		height: 0,
	}
	
	vertex = [];
	temporary = vertex_create_buffer();
	
	static push = function(bla) {
		array_push(dialogs, bla);
	}
	
	static blabber_text = function(element) {
		if (element[BLABBER_TEXT.BUFFER] == pointer_null) {
			font = element[BLABBER_TEXT.FONT];
			
			var index = array_find_index(vertex, function(e) {
				return (e.font == font);
			});
			
			if (index == -1) {
				index = {
					font: element[BLABBER_TEXT.FONT],
					texture: font_get_texture(element[BLABBER_TEXT.FONT]),
					buffer: vertex_create_buffer(),
					
					length: 0,
				}
				
				vertex_begin(index.buffer, DIALOG_SYSTEM_FORMAT);
				vertex_end(index.buffer);
				
				array_push(vertex, index);
			}
			
			element[BLABBER_TEXT.BUFFER] = index;
		}
		
		var n = (element[BLABBER_TEXT.TIME] > 0) ? floor(time / element[BLABBER_TEXT.TIME]) : element[BLABBER_TEXT.LENGTH];
		repeat (n) {
			length++;
			append_char(element[BLABBER_TEXT.BUFFER], string_char_at(element[BLABBER_TEXT.TEXT], length), element[BLABBER_TEXT.FONT], element[BLABBER_TEXT.COLOR], element[BLABBER_TEXT.ALPHA]);	
			time = time - floor(time);
		}
		
		if (length >= element[BLABBER_TEXT.LENGTH]) {
			self.index++;
			length = 0;
		}	
	}
	
	static blabber_rewrite = function(element, previous) {
		var n = (element[BLABBER_TEXT.TIME] > 0) ? floor(time / element[BLABBER_TEXT.TIME]) : element[BLABBER_TEXT.LENGTH];
		repeat (n) {
			time = time - floor(time);
			var index = string_distance(previous[BLABBER_TEXT.TEXT], element[BLABBER_TEXT.TEXT]);
			
			//exit and advance if no change needed
			if (index == 0) {
				self.index++;
				length = 0;
				time = 0;
				
				return;
			}
		}
	}
	
	static step = function() {
		var current = dialogs[0];
		if (index >= array_length(current.stack)) return;

		var element = current.stack[index];

		time += (delta_time / 1000);
		
		switch (element[BLABBER.TYPE]) {
		case BLABBER.TEXT:
			blabber_text(element);
			break;
		case BLABBER.NEW_LINE:
			cursor.x = 0;
			cursor.y += line.height;
			index++;
			time = 0;
			break;
		case BLABBER.REWRITE: 
			blabber_rewrite(element, current.stack[index - 1]);
			break;
		}

	}
	
	static render = function() {
		for(var i = 0; i < array_length(vertex); i++) {
			var v = vertex[i];
			
			vertex_submit(v.buffer, pr_trianglelist, v.texture);
		}
	}
	
	static cleanup = function() {
		for(var i = 0; i < array_length(vertex); i++) {
			vertex_delete_buffer(vertex[i].buffer);	
		}
		
		vertex_delete_buffer(temporary);
	}
}

enum BLABBER { TYPE, TEXT, SPRITE, NEW_LINE, REWRITE };
enum BLABBER_TEXT { TYPE, TEXT, TIME, COLOR, ALPHA, FONT, FLAGS, LENGTH, BUFFER };

function Blabber(Flags = 0, onCharacter = undefined, w, h) constructor {
	stack = [];
	//events
	
	//execute a function on character change
	//arguments 
	//type - (character, sprite, new_line)
	/*value - 
		char - string
		sprite - asset_sprite
		new_line - pointer_null
	*/
	//flags - the flags variable that was passed
	self.onCharacter = onCharacter ?? function(type, char, flags) {
		show_debug_message("Type - " + string(type) + " / Char - " + string(char) + " / Flags - " + string(flags));
	};
	
	//text - the string to render
	//time - the time each chararacter is give before a new one is rendered (in ms)
	//color - the color of the text
	//alpha - the opacity of the text
	static text = function(text, time = 1, color = c_white, alpha = 1, font = FALLBACK_FONT, flags = 0) {
		array_push(stack, [
			BLABBER.TEXT,
			text, time,
			color, alpha,
			font,
			flags,
			string_length(text),
			pointer_null,
		])
	}
	
	static sprite = function(index, image, time = 0, color = c_white, alpha = 1) {
		array_push(stack, [BLABBER.SPRITE, index, image, time, color, alpha]);
	};
	
	static rewrite = function(text, time) {
		array_push(stack, [BLABBER.REWRITE, text, time]);
	}
	
	//move the cursor to a new line	
	static new_line = function() {
		array_push(stack, [BLABBER.NEW_LINE]);
	}
}