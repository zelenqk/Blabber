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
		case BLABBER.NEW_LINE:
			cursor.x = 0;
			cursor.y += cursor.height;
			
			cursor.width = 0;
			cursor.height = 0;
			return true;
		case BLABBER.BACKSPACE:
			if (element[BLABBER_BACKSPACE.AMOUNT]-- <= 0) {
				 array_delete(current.stack, index--, 1);
				 return true;
			}
			
			var previous = current.stack[index - 1];
			switch (previous[BLABBER.TYPE]) {
			case BLABBER.TEXT:	
				var pos = previous[BLABBER_TEXT.LENGTH]--;
				var char = string_char_at(previous[BLABBER_TEXT.TEXT], pos);
				var info = font_get_info(previous[BLABBER_TEXT.FONT]);
				var glyph = info.glyphs[$ char];
				
				cursor.x -= glyph.shift;
				remove_quad(previous[BLABBER_TEXT.BUFFER], previous[BLABBER_TEXT.START] + pos - 1);
				
				if (previous[BLABBER_TEXT.LENGTH] == 0) {
					index--;
					array_delete(current.stack, index, 1);
					return false;
				}
				
				return false;
			default:
				array_delete(current.stack, index - 1, 1);
				return false;
			}
			return false;
		case BLABBER.WAIT:
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
	
	static step = function() {
		if (current == pointer_null) return;
		time += (delta_time / 1000);
	
		while (true) {
			var element = current.stack[index];
			if (time < element[BLABBER.TIME]) break;
		
			time -= element[BLABBER.TIME];
			if (advance(element)) if (increment()) break;	//fuck you
		}
	}
	
	static render = function() {
		for(var i = 0; i < array_length(vertex); i++) {
			vertex_submit(vertex[i].buffer, pr_trianglelist, vertex[i].texture);	
		}
	}
	
	static cleanup = function() {
		for(var i = 0; i < array_length(vertex); i++) {
			vertex_delete_buffer(vertex[i].buffer);	
		}
		
		vertex_delete_buffer(temporary);
	}
}

enum BLABBER { TYPE, TIME, TEXT, NEW_LINE, WAIT, BACKSPACE };
enum BLABBER_TEXT { TYPE, TIME, TEXT, FONT, COLOR, ALPHA, WIDTH, HEIGHT, BUFFER, START, LENGTH };
enum BLABBER_BACKSPACE { TYPE, TIME, AMOUNT };

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

		element[BLABBER_TEXT.WIDTH] = 0;
		element[BLABBER_TEXT.HEIGHT] = 0;
		
		var info = font_get_info(font);
		
		var i = 0;
		repeat (length) {
			var char = string_char_at(text, i++);
			var glyph = info.glyphs[$ char];
			
			element[BLABBER_TEXT.WIDTH] += glyph.shift;
			element[BLABBER_TEXT.HEIGHT] = max(glyph.h, element[BLABBER_TEXT.HEIGHT]);
		}
		
		array_push(stack, element);
	}
	
	static new_line = function(time = 0) {
		array_push(stack, [BLABBER.NEW_LINE, time])	
	}
	
	static backspace = function(amount, time = 1) {
		array_push(stack, [BLABBER.BACKSPACE, time, amount]);
	}
	static wait = function(time = 1) {
		array_push(stack, [BLABBER.WAIT, time]);
	}
}