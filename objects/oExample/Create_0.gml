dialog = new Blabber(150);

hello = new Chatter();
hello.text("Hello, World!", 64);
hello.text("How's it hangin?", 64);
hello.wait(100);

hello.increment_cursor_y(120);
hello.text("ooo im over here", 64);
hello.wait(1000);

hello.backspace(13 + 16 + 16, 64 );

dialog.push(hello);

spd = 1;