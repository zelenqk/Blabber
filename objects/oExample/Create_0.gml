dialog = new Blabber();

hello = new Chatter();
hello.text("Hello, World!", 64);
hello.new_line();
hello.text("How's it hangin?", 64);
hello.wait(1000);
hello.new_line();
hello.text("I know your ", 128, c_white);
hello.text("secret", 128, c_red);
hello.text(".", 256, c_white);
hello.text(".", 256, c_white);
hello.text(".", 256, c_white);
hello.backspace(9, 64);
hello.text("birthday is tomorow! :D", 64, c_white);

dialog.push(hello);