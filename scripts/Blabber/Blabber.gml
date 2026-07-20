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
	static Vertex = function(tex) constructor {
		texture = tex;
		
		buffer = vertex_create_buffer();
		length = 0;
		
		width = texture_get_texel_width(texture);
		height = texture_get_texel_height(texture);
		
		vertex_begin(buffer, BLABBER_VERTEX_FORMAT);
		vertex_end(buffer);
	}
	
	//internal methods
	static grab_cursor = function() {
		return [cursor.x, cursor.y, cursor.width, cursor.height];	
	}
	
	static set_cursor = function(c) {
		cursor.x = c[0];
		cursor.y = c[1];
		cursor.width	= c[2];
		cursor.height	= c[3];
	}
	
	static increment = function() {
		index++;
		length = 1;
		
		if (index >= array_length(current.stack)) {
			current = pointer_null;
			return true;
		}
		
		var element = current.stack[index];
		switch (element[BLABBER.TYPE]) {
		case BLABBER.TEXT:
			texture = font_get_texture(element[BLABBER_TEXT.FONT]);
			
			var buf = array_find_index(vertex, function(e) {
				return (e.texture == texture);
			});
			
			if (buf == -1) {
				buf = new Vertex(texture);
				array_push(vertex, buf);
			}else buf = vertex[buf];
			
			element[BLABBER_TEXT.BUFFER] = buf;
			element[BLABBER_TEXT.START] = buf.length;
			break;
		case BLABBER.SPRITE:
			texture = font_get_texture(element[BLABBER_TEXT.FONT]);
			
			var buf = array_find_index(vertex, function(e) {
				return (e.texture == texture);
			});
			
			if (buf == -1) {
				buf = new Vertex(texture);
				array_push(vertex, buf);
			}else buf = vertex[buf];
			
			element[BLABBER_SPRITE.BUFFER] = buf;
			element[BLABBER_SPRITE.START] = buf.length;
			break;
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
			
			if (element[BLABBER_TEXT.ONCHAR] != undefined) element[BLABBER_TEXT.ONCHAR](char, length, element[BLABBER_TEXT.TEXT], cursor);
			
			cursor.x += glyph.shift;
			cursor.height = max(cursor.height, glyph.h);
			return (length > element[BLABBER_TEXT.LENGTH]);
		case BLABBER.SPRITE:
			var buffer = element[BLABBER_SPRITE.BUFFER];
			var tw = buffer.width;
			var th = buffer.height;
			
			var scale = cursor.height / element[BLABBER_SPRITE.HEIGHT];
			var w = element[BLABBER_SPRITE.WIDTH] * scale;
			var h = element[BLABBER_SPRITE.HEIGHT] * scale;
			
			if (cursor.x >= width or cursor.x + w > width) {
				array_insert(current.stack, index + 1, [BLABBER.NEWLINE, 0, grab_cursor(), true, 1]);
				cursor.x = 0;
				cursor.y += cursor.height;
				
				cursor.width = 0;
				cursor.height = 0;
			}
			
			append_quad(
				buffer,
				buffer.length++,
				
				cursor.x,
				cursor.y,
				w, h,
				
				element[BLABBER_SPRITE.UV][0],
				element[BLABBER_SPRITE.UV][1],
				element[BLABBER_SPRITE.UV][2] - element[BLABBER_SPRITE.UV][0],
				element[BLABBER_SPRITE.UV][3] - element[BLABBER_SPRITE.UV][1],
				
				element[BLABBER_TEXT.COLOR],
				element[BLABBER_TEXT.ALPHA],
			);
			
			return true;
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
		array_push(dialogs, bla);
		
		if (current == pointer_null) {
			current = bla;
			index = -1;
			
			increment();
		}
	}
	static step = function(modifier = 1) {
		if (current == pointer_null) return;
		time += (delta_time / 1000) * modifier;
	
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

enum BLABBER { TYPE, TIME, TEXT, NEWLINE, WAIT, BACKSPACE, SPRITE, CURSOR_X, CURSOR_Y, CURSOR_POS, ICURSOR_X, ICURSOR_Y, ICURSOR_POS };
enum BLABBER_TEXT { TYPE, TIME, TEXT, FONT, COLOR, ALPHA, ONCHAR, BUFFER, START, LENGTH };
enum BLABBER_SPRITE { TYPE, TIME, INDEX, IMAGE, COLOR, ALPHA, WIDTH, HEIGHT, UV, BUFFER, START };
enum BLABBER_NEWLINE { TYPE, TIME, PREVIOUS, DYNAMIC, LENGTH};
enum BLABBER_BACKSPACE { TYPE, TIME, AMOUNT };

enum BLABBER_CURSOR {TYPE, TIME, POS, PREVIOUS};

function Chatter() constructor {
	stack = [];
	
	static text = function(text, time = 0, color = c_white, alpha = 1, font = FALLBACK_FONT, onCharacter = undefined) {
		var element = array_create(BLABBER_TEXT.LENGTH, BLABBER.TEXT);
		element[BLABBER_TEXT.TIME] = time;
		
		element[BLABBER_TEXT.TEXT] = text;
		element[BLABBER_TEXT.FONT] = font;
		
		var length = string_length(text);
		element[BLABBER_TEXT.LENGTH] = length;

		element[BLABBER_TEXT.COLOR] = color;
		element[BLABBER_TEXT.ALPHA] = alpha;
		element[BLABBER_TEXT.ONCHAR] = onCharacter;

		array_push(stack, element);
	}
	
	static sprite = function(index, time = 0, image = 0, color = c_white, alpha = 1) {
		array_push(stack, [BLABBER.SPRITE, time, index, image, color, alpha, sprite_get_width(index), sprite_get_height(index), sprite_get_uvs(index, image), pointer_null, 0]);	
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