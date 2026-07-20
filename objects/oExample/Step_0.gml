if (keyboard_check(vk_space)) spd = 5;
else spd = 1;

if (keyboard_check_pressed(vk_shift)) dialog.pop();

dialog.step(spd);