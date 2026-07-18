//a - authority
//b - clone

function string_distance(a, b, dir = 1){
	var length = string_length(a);
	var lengthB = string_length(b);

	var i = dir == 1 ? 1 : length;
	var u = dir == 1 ? 1 : lengthB;
	repeat (length) {
		repeat (lengthB) {
			if (string_char_at(a, i) != string_char_at(b, u)) return u;
			i += dir;
			u += dir;
		}
	}
	
	return 0;
}
