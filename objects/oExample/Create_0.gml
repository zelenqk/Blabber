dialog = new Blabber(140);

hello = new Chatter();
hello.text("Hello, World!", 64);
hello.text("How's it hangin?", 64);
hello.wait(1000);
hello.backspace(16, 64);

dialog.push(hello);

spd = 1;