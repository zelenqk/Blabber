dialog = new Blabber(150);

hello = new Chatter();
hello.text("Hello, World!", 64);
hello.text("How's it hangin?", 64);
hello.wait(100);

hello.text("ooo im over here", 64);
hello.sprite(sGlassesEmoji);

hello.wait(3300);
hello.backspace(9, 64);

dialog.push(hello);

something = new Chatter();
something.text("THis is Not NiEC", 64, c_white, 1, fntDejaVu_Sans);
dialog.push(something);

spd = 1;