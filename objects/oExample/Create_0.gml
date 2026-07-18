dialogue = new Blabber();

test = new Chatter();
test.text("Hello world!", 64);
test.new_line();
test.text("New dialog system, who dis?", 64, c_white);
test.new_line();
test.text("its ", 32, c_white);
test.text("zelensky", 32, c_green);
test.rewrite("its zelenqk", 128);

dialogue.push(test);