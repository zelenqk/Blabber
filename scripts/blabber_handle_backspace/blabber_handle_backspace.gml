function blabber_handle_backspace(element, previous){
	if (element[BLABBER_BACKSPACE.AMOUNT]-- <= 0) {
		 array_delete(current.stack, index--, 1);
		 return true;
	}
	
	switch (previous[BLABBER.TYPE]) {
	case BLABBER.TEXT:	
		var pos = previous[BLABBER_TEXT.LENGTH]--;
		var char = string_char_at(previous[BLABBER_TEXT.TEXT], pos);
		var info = font_get_info(previous[BLABBER_TEXT.FONT]);
		var glyph = info.glyphs[$ char];
		
		cursor.x -= glyph.shift;
		remove_quad(previous[BLABBER_TEXT.BUFFER], previous[BLABBER_TEXT.START] + pos - 1);
		
		if (previous[BLABBER_TEXT.LENGTH] == 0) {
			array_delete(current.stack, index-- - 1, 1);
			return false;
		}
		
		return false;
	case BLABBER.NEWLINE:
		if (previous[BLABBER_NEWLINE.LENGTH] == 0) {
			set_cursor(previous[BLABBER_NEWLINE.PREVIOUS])
			if (previous[BLABBER_NEWLINE.DYNAMIC]) element[BLABBER_BACKSPACE.AMOUNT]++;
			
			array_delete(current.stack, index-- - 1, 1);
			return false;
		}
		
		previous[BLABBER_NEWLINE.LENGTH]--;
		element[BLABBER_BACKSPACE.AMOUNT]++;
		
		return blabber_handle_backspace(element, current.stack[index - 2]);
	
	//cursors
	case BLABBER.CURSOR_Y:
	case BLABBER.ICURSOR_Y:
	case BLABBER.CURSOR_X:
	case BLABBER.ICURSOR_X:
	case BLABBER.ICURSOR_POS:
	case BLABBER.CURSOR_POS:
		set_cursor(previous[BLABBER_CURSOR.PREVIOUS])
		array_delete(current.stack, index-- - 1, 1);
		return false;

	default:
		array_delete(current.stack, index-- - 1, 1);
		return false;
	}
}