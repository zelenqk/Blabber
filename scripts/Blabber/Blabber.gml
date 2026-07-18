globalvar FALLBACK_FONT, BLABBER_VERTEX_FORMAT;

vertex_format_begin();
vertex_format_add_position();
vertex_format_add_color();
vertex_format_add_texcoord();

BLABBER_VERTEX_FORMAT = vertex_format_end();
FALLBACK_FONT = fntAriel;

function Blabber(w = display_get_gui_width(), h = display_get_gui_height() / 5) constructor {
	dialogs = [];
	
	width = w;
	height = h;
	
	time = 0;
	
	index = 0;
	current = pointer_null;
	temporary = vertex_create_buffer();

	length = 1;
	
	cursor = {x: 0, y: 0, width: 0, height: 0};
	//cache
	vertex = [];
	
	static Vertex = function(fnt) constructor {
		buffer = vertex_create_buffer();
		length = 0;
		
		font = fnt;
		texture = font_get_texture(font);
		
		vertex_begin(buffer, BLABBER_VERTEX_FORMAT);
		vertex_end(buffer);
	}
	
	static increment = function(){
		index++;
		time = 0;
		
		current.stack[index][BLABBER.START] = length + current.stack[index - 1][BLABBER.START];

		length = 1;
		
		if (array_length(current.stack) <= index) current = pointer_null;
		else {
			step = step_time;
			if (current.stack[index][BLABBER.TIME] == 0) step = step_instant
			
		}
	}
	
	static advance = function(element) {
		time = time - floor(time);
		
		switch (element[BLABBER.TYPE]) {
		case BLABBER.TEXT:
			if (element[BLABBER_TEXT.BUFFER] == pointer_null) {
				font = element[BLABBER_TEXT.FONT];
				
				var buffer = array_find_index(vertex, function(e) {
					return (e.font == font);	
				});
			
				if (buffer == -1) {
					element[BLABBER_TEXT.BUFFER] = new Vertex(font)
					array_push(vertex, element[BLABBER_TEXT.BUFFER]);
				}else element[BLABBER_TEXT.BUFFER] = vertex[buffer];
			}
			
			var char = string_char_at(element[BLABBER_TEXT.TEXT], length++);
			var info = font_get_info(element[BLABBER_TEXT.FONT]);
			var glyph = info.glyphs[$ char];
			
			var buffer = element[BLABBER_TEXT.BUFFER];
			var tw = texture_get_texel_width(buffer.texture);
			var th = texture_get_texel_height(buffer.texture);
			
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
			
			if (length > string_length(element[BLABBER_TEXT.TEXT])) {
				increment();
				return true;
			}
			break;
		case BLABBER.NEW_LINE:
				cursor.x = 0;
				cursor.y += cursor.height;
				cursor.height = 0;
				cursor.width = 0;
				
				increment();
				return true;
			break;
		case BLABBER.REWRITE:
			var previous =  current.stack[index - 1];
			var ind = string_distance(element[BLABBER_TEXT.TEXT], previous[BLABBER_REWRITE.TEXT]);
			
			if (ind != 0) {
				if (previous[BLABBER_TEXT.LENGTH] <= string_length(element[BLABBER_REWRITE.TEXT])) {
					var pos = previous[BLABBER_TEXT.LENGTH]--;
					var char = string_char_at(previous[BLABBER_TEXT.TEXT], pos);
					var info = font_get_info(previous[BLABBER_TEXT.FONT]);
					var glyph = info.glyphs[$ char];
					
					cursor.x -= glyph.shift;
					remove_quad(previous[BLABBER_TEXT.BUFFER], previous[BLABBER.START] + pos);
					
				}else append_quad(
					
				)
			}
			
			break;
		}
		
		return false;
	}
	
	//methods
	push = function(bla) {
		if (array_length(dialogs) == 0) {
			current = bla;
			index = 0;
			
			step = step_time;
			if (bla.stack[0][BLABBER.TIME] == 0) step = step_instant;
		}
		
		array_push(dialogs, bla);
	}
	
	static step_instant = function() {
		if (current == pointer_null) return;
		var element = current.stack[index];
		
		var n = (element[BLABBER.TYPE] == BLABBER.TEXT) ? string_length(element[BLABBER_TEXT.TEXT]) : 1;
		repeat (n) if (advance(element)) break;	//fuck you
	}
	
	static step_time = function() {
		if (current == pointer_null) return;
		var element = current.stack[index];
		
		time += (delta_time / 1000);	//miliseconds
		
		var n = floor(time div element[BLABBER.TIME]);
		repeat (n) if (advance(element)) break;	//fuck you
		
	}
	
	static render = function() {
		var l = array_length(vertex);
		var i = 0;
		
		repeat (l) vertex_submit(vertex[i].buffer, pr_trianglelist, vertex[i].texture); i++;
	}
}

enum BLABBER { TYPE, TIME, START , TEXT, SPRITE, NEW_LINE, REWRITE };
enum BLABBER_TEXT { TYPE, TIME, START, TEXT, COLOR, ALPHA, FONT, FLAGS, LENGTH, BUFFER};
enum BLABBER_REWRITE { TYPE, TIME, START, TEXT };

function Chatter(Flags = 0, onCharacter = undefined, w, h) constructor {
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
	self.onCharacter = onCharacter ?? function(type, char, flags) {};
	
	//prefabs
	
	//text - the string to render
	//time - the time each chararacter is give before a new one is rendered (in ms)
	//color - the color of the text
	//alpha - the opacity of the text
	static text = function(text, time = 1, color = c_white, alpha = 1, font = FALLBACK_FONT, flags = 0) {
		array_push(stack, [
			BLABBER.TEXT, time, 0,
			text,
			color, alpha,
			font,
			flags,
			string_length(text),
			pointer_null,
			0
		])
	}
	
	static sprite = function(index, image, time = 0, color = c_white, alpha = 1) {
		array_push(stack, [BLABBER.SPRITE, time, 0, index, image, color, alpha]);
	};
	
	static rewrite = function(text, time = 0) {
		array_push(stack, [BLABBER.REWRITE, time, 0, text]);
	}
	
	//move the cursor to a new line	
	static new_line = function(time = 0) {
		array_push(stack, [BLABBER.NEW_LINE, time, 0]);
	}
}