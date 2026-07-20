dialog = new Blabber(150);

hello = new Chatter();
hello.text("Hello, World!", 64);
hello.text("How's it hangin?", 64);
hello.wait(100);

hello.backspace(9, 64);
hello.text("ooo im over here", 64);
hello.sprite(sGlassesEmoji);

dialog.push(hello);

spd = 1;