function append_char(vertex, char, font = FALLBACK_FONT, color = c_white, alpha = 1) {
	draw_set_font(font);
	draw_text(0, 0, char);
	
	var info = font_get_info(font);
	self.font = font;
	
	var glyph = info.glyphs[$ char];
	var cx = cursor.x + glyph.offset;
	var cy = cursor.y + glyph.yoffset;
	
	var tx = (glyph.x * texture_get_texel_width(info.texture));
	var ty = (glyph.y * texture_get_texel_height(info.texture));
	var tw = (glyph.w * texture_get_texel_width(info.texture));
	var th = (glyph.h * texture_get_texel_height(info.texture));
	
	vertex_begin(temporary, DIALOG_SYSTEM_FORMAT);
		vertex_position(temporary, cx, cy); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, tx, ty);
		vertex_position(temporary, cx + glyph.w, cy); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, tx + tw, ty);
		vertex_position(temporary, cx + glyph.w, cy + glyph.h); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, tx + tw, ty + th);
		
		vertex_position(temporary, cx, cy); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, tx, ty);
		vertex_position(temporary, cx, cy + glyph.h); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, tx, ty + th);
		vertex_position(temporary, cx + glyph.w, cy + glyph.h); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, tx + tw, ty + th);
	vertex_end(temporary);
	
	line.height = max(line.height, glyph.h + glyph.yoffset);
	cursor.x += glyph.shift;
	
	vertex_update_buffer_from_vertex(vertex.buffer, vertex.length++ * 6, temporary);
}

//we cant really remove it so we just make an empty one
function remove_quad(vertex, index) {
	vertex_begin(temporary, DIALOG_SYSTEM_FORMAT);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
	vertex_end(temporary);
	
	vertex_update_buffer_from_vertex(vertex.buffer, index, temporary);
}