function append_quad(vertex, index, cx, cy, w, h, ux, uy, uw, uh, color, alpha) {
	vertex_begin(temporary, BLABBER_VERTEX_FORMAT);
		vertex_position(temporary, cx, cy); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, ux, uy);
		vertex_position(temporary, cx + w, cy); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, ux + uw, uy);
		vertex_position(temporary, cx + w, cy + h); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, ux + uw, uy + uh);
		
		vertex_position(temporary, cx, cy); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, ux, uy);
		vertex_position(temporary, cx, cy + h); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, ux, uy + uh);
		vertex_position(temporary, cx + w, cy + h); vertex_color(temporary, color, alpha); vertex_texcoord(temporary, ux + uw, uy + uh);
	vertex_end(temporary);
	
	vertex_update_buffer_from_vertex(vertex.buffer, index * 6, temporary);
}

//we cant really remove it so we just make an empty one
function remove_quad(vertex, index) {
	vertex_begin(temporary, BLABBER_VERTEX_FORMAT);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
		vertex_position(temporary, 0, 0); vertex_color(temporary, 0, 0); vertex_texcoord(temporary, 0, 0);
	vertex_end(temporary);
	
	vertex_update_buffer_from_vertex(vertex.buffer, index * 6, temporary);
}