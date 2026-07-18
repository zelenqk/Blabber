# <img width="64" height="64" alt="blabber_logo" src="https://github.com/user-attachments/assets/0f478270-22d4-442c-b47e-1341cd0bf2c8" /> Blabber

Blabber is a dialog system for GameMaker.

Blabber only handles text rendering. To build dialog boxes or other UI around it you would have to render it to a surface or use something else.

## Installation

Download the latest release, then in the GameMaker IDE go to `Tools > Import Local Package`.

## Usage

Create a Blabber context in one of your objects:

```gml
// create event
blabber = new Blabber(width);

// step event
blabber.step();

// draw event
blabber.render();

// cleanup event
blabber.cleanup();
```
