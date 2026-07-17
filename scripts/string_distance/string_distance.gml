//a - authority
//b - clone

function string_distance(a, b){
	var length = string_length(a);
	var lengthB = string_length(b);

	var i = length;
	var u = lengthB;
	repeat (length) {
		repeat (lengthB) {
			if (string_char_at(a, i--) != string_char_at(b, u--)) return u + 1;
		}
	}
	
	return 0;
}
