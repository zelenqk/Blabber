globalvar BLABBER_VERTEX_FORMAT, FALLBACK_FONT;

vertex_format_begin();
vertex_format_add_position();
vertex_format_add_color();
vertex_format_add_texcoord();
BLABBER_VERTEX_FORMAT = vertex_format_end();
FALLBACK_FONT = fntDejaVu_Sans;

function Blabber(w = display_get_gui_width()) constructor {
	width = w;

	time = 0;
	dialogs = [];
	
	index = 0;
	current = pointer_null;
	previous = pointer_null;
	
	length = 1;
	
	vertex = [];
	temporary = vertex_create_buffer();
	
	cursor = {x: 0, y: 0, width: 0, height: 0};
	
	//internal classes
	static Vertex = function(fnt) constructor {
		font = fnt;
		texture = font_get_texture(font);
		
		buffer = vertex_create_buffer();
		length = 0;
		
		width = texture_get_texel_width(texture);
		height = texture_get_texel_height(texture);
		
		vertex_begin(buffer, BLABBER_VERTEX_FORMAT);
		vertex_end(buffer);
	}
	
	static grab_cursor = function() {
		return [cursor.x, cursor.y, cursor.width, cursor.height];	
	}
	
	static set_cursor = function(c) {
		cursor.x = c[0];
		cursor.y = c[1];
		cursor.width	= c[2];
		cursor.height	= c[3];
	}
	
	//internal methods
	static increment = function() {
		index++;
		length = 1;
		
		if (index >= array_length(current.stack)) {
			current = pointer_null;
			return true;
		}
		
		var element = current.stack[index];
		if (element[BLABBER.TYPE] == BLABBER.TEXT) {
			font = element[BLABBER_TEXT.FONT];
			
			var buf = array_find_index(vertex, function(e) {
				return (e.font == font);
			});
			
			if (buf == -1) {
				buf = new Vertex(font);
				array_push(vertex, buf);
			}else buf = vertex[buf];
			
			element[BLABBER_TEXT.BUFFER] = buf;
			element[BLABBER_TEXT.START] = buf.length;
		}
		
		while (element[BLABBER.TIME] == 0) if (advance(element)) return increment();
		return false;
	}
	
	static advance = function(element) {
		switch (element[BLABBER.TYPE]) {
		case BLABBER.TEXT:
			var char = string_char_at(element[BLABBER_TEXT.TEXT], length++);
			var info = font_get_info(element[BLABBER_TEXT.FONT]);
			var glyph = info.glyphs[$ char];
			
			var buffer = element[BLABBER_TEXT.BUFFER];
			var tw = buffer.width;
			var th = buffer.height;
			
			if (cursor.x >= width or cursor.x + glyph.shift > width) {
				array_insert(current.stack, index + 1, [BLABBER.NEWLINE, 0, grab_cursor(), true, element[BLABBER_TEXT.LENGTH] - (length - 1)]);
				cursor.x = 0;
				cursor.y += cursor.height;
				
				cursor.width = 0;
				cursor.height = 0;
			}
			
			append_quad(
				buffer,
				buffer.length++,
				
				cursor.x + glyph.offset,
				cursor.y + glyph.yoffset,
				glyph.w, glyph.h,
				
				glyph.x * tw,
				glyph.y * th,
				glyph.w * tw,
				glyph.h * th,
				
				element[BLABBER_TEXT.COLOR],
				element[BLABBER_TEXT.ALPHA],
			);
			
			cursor.x += glyph.shift;
			cursor.height = max(cursor.height, glyph.h);
			return (length > element[BLABBER_TEXT.LENGTH]);
		case BLABBER.NEWLINE:
			if (element[BLABBER_NEWLINE.DYNAMIC]) return true;
			
			element[BLABBER_NEWLINE.PREVIOUS][0] = cursor.x;
			element[BLABBER_NEWLINE.PREVIOUS][1] = cursor.y;
			
			cursor.x = 0;
			cursor.y += cursor.height;
			
			cursor.width = 0;
			cursor.height = 0;
			return true;
		case BLABBER.BACKSPACE:
			var previous = current.stack[index - 1];
			return blabber_handle_backspace(element, previous);
		case BLABBER.WAIT:
			array_delete(current.stack, index--, 1);
			test = element;
			return true;
			
		//cursor
		case BLABBER.CURSOR_POS:
			element[BLABBER_CURSOR.PREVIOUS] = grab_cursor();
			cursor.x = element[BLABBER_CURSOR.POS][0];
			cursor.y = element[BLABBER_CURSOR.POS][1];
			return true;
		case BLABBER.ICURSOR_POS:
			element[BLABBER_CURSOR.PREVIOUS] = grab_cursor();
			cursor.x += element[BLABBER_CURSOR.POS][0];
			cursor.y += element[BLABBER_CURSOR.POS][1];
			return true;
		case BLABBER.CURSOR_X:
			element[BLABBER_CURSOR.PREVIOUS] = grab_cursor();
			cursor.x = element[BLABBER_CURSOR.POS];
			return true;
		case BLABBER.CURSOR_Y:
			element[BLABBER_CURSOR.PREVIOUS] = grab_cursor();
			cursor.y = element[BLABBER_CURSOR.POS];
			return true;
		case BLABBER.ICURSOR_X:
			element[BLABBER_CURSOR.PREVIOUS] = grab_cursor();
			cursor.x += element[BLABBER_CURSOR.POS];
			return true;
		case BLABBER.ICURSOR_Y:
			element[BLABBER_CURSOR.PREVIOUS] = grab_cursor();
			cursor.y += element[BLABBER_CURSOR.POS];
			return true;
		}
		
		return true;
	}
	
	//methods
	static pop = function() {
		if (array_length(dialogs) == 0) return; 
		array_delete(dialogs, 0, 1);
		
		if (array_length(dialogs) == 0) current = pointer_null;
		else current = dialogs[0];
	}
	
	static push = function(bla) {
		if (array_length(dialogs) == 0) current = bla;
		array_push(dialogs, bla);
		
		var element = bla.stack[0];
		if (element[BLABBER.TYPE] == BLABBER.TEXT) {
			font = element[BLABBER_TEXT.FONT];
			
			var buf = array_find_index(vertex, function(e) {
				return (e.font == font);
			});
			
			if (buf == -1) {
				buf = new Vertex(font);
				array_push(vertex, buf);
			}
			
			element[BLABBER_TEXT.BUFFER] = buf;
			element[BLABBER_TEXT.START] = buf.length;
		}
	}
	///@function step
	///@argument speed
	static step = function(spd = 1) {
		if (current == pointer_null) return;
		time += (delta_time / 1000) * spd;
	
		while (true) {
			var element = current.stack[index];
			if (time < element[BLABBER.TIME]) break;
		
			time -= element[BLABBER.TIME];
			if (advance(element)) if (increment()) break;	//fuck you
		}
	}
	
	static render = function(dbg = false) {
		for(var i = 0; i < array_length(vertex); i++) {
			vertex_submit(vertex[i].buffer, pr_trianglelist, vertex[i].texture);	
		}
		
		if (dbg) draw_line(cursor.x, cursor.y + cursor.height, cursor.x + 12, cursor.y + cursor.height);
	}
	
	static cleanup = function() {
		for(var i = 0; i < array_length(vertex); i++) {
			vertex_delete_buffer(vertex[i].buffer);	
		}
		
		vertex_delete_buffer(temporary);
	}
}

enum BLABBER { TYPE, TIME, TEXT, NEWLINE, WAIT, BACKSPACE, CURSOR_X, CURSOR_Y, CURSOR_POS, ICURSOR_X, ICURSOR_Y, ICURSOR_POS };
enum BLABBER_TEXT { TYPE, TIME, TEXT, FONT, COLOR, ALPHA, BUFFER, START, LENGTH };
enum BLABBER_NEWLINE { TYPE, TIME, PREVIOUS, DYNAMIC, LENGTH};
enum BLABBER_BACKSPACE { TYPE, TIME, AMOUNT };

enum BLABBER_CURSOR {TYPE, TIME, POS, PREVIOUS};

function Chatter() constructor {
	stack = [];
	
	static text = function(text, time = 0, color = c_white, alpha = 1, font = FALLBACK_FONT) {
		var element = array_create(BLABBER_TEXT.LENGTH, BLABBER.TEXT);
		element[BLABBER_TEXT.TIME] = time;
		
		element[BLABBER_TEXT.TEXT] = text;
		element[BLABBER_TEXT.FONT] = font;
		
		var length = string_length(text);
		element[BLABBER_TEXT.LENGTH] = length;

		element[BLABBER_TEXT.COLOR] = color;
		element[BLABBER_TEXT.ALPHA] = alpha;

		array_push(stack, element);
	}
	
	static new_line = function(time = 0) {
		array_push(stack, [BLABBER.NEWLINE, time, [0, 0, 0, 0], false, 0])	
	}
	
	static backspace = function(amount, time = 1) {
		array_push(stack, [BLABBER.BACKSPACE, time, amount]);
	}
	
	static wait = function(time = 1) {
		array_push(stack, [BLABBER.WAIT, time]);
	}
	
	//cursor
	static set_cursor_pos = function(X, Y, time = 0) {
		array_push(stack, [BLABBER.CURSOR_POS, time, X, Y, [0, 0]]);
	}
	
	static set_cursor_x = function(X, time = 0) {
		array_push(stack, [BLABBER.CURSOR_X, time, X, 0]);
	}
	
	static set_cursor_y = function(Y, time = 0) {
		array_push(stack, [BLABBER.CURSOR_Y, time, Y, 0]);
	}
	
	static set_cursor_pos = function(X, Y, time = 0) {
		array_push(stack, [BLABBER.ICURSOR_POS, time, X, Y, [0, 0]]);
	}
	
	static increment_cursor_x = function(X, time = 0) {
		array_push(stack, [BLABBER.ICURSOR_X, time, X, 0]);
	}
	
	static increment_cursor_y = function(Y, time = 0) {
		array_push(stack, [BLABBER.ICURSOR_Y, time, Y, 0]);
	}
}