## Files Architecture

This is a document iterating the location and distribution of elixir files and how game logic works with commands for learning where things belong in Ex_Venture.


### Commands

For creating new commands, here are examples of where other commands are distributed.

#### Whisper Command

1. command.ex - /lib/game/
2. message.ex - /lib/game/
3. whisper.ex - /lib/game/command/
4. room_whispered.ex - /lib/game/events/
5. channels.ex - /lib/game/format
6. character.ex - /lib/game/session/
7. gmcp.ex - /lib/game/session/
8. command_test.exs - /test/game/
9. whisper_test.exs - /test/game/command/

#### Equipment Command

1. command.ex - /lib/game/
2. equipment.ex - /lib/game/command/
3. items.ex - /lib/game/format/
4. command_test.exs - /test/game/
5. equipment_test.exs - /test/game/command/

#### Examine Command

1. command.ex - /lib/game/
2. examine.ex - /lib/game/command/
3. command_test.exs - /test/game/
4. examine_test.exs - /test/game/command



### Game Logic

### Web Architecture

#### Play View

#### Admin View

#### Base Page View

#### Character Creation View
/lib/web/templates/character

