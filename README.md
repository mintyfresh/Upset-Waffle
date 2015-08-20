Upset Waffle
============

A markov chain powered text generator, written in D. Ships with a simple REPL.

### How-To

Compile and run.

`dmd source/*.d`

Or just use,

`dub`

### The REPL

| Command    | Short | Arguments        | Description                                                            |
|------------|-------|------------------|------------------------------------------------------------------------|
| train      | t     | [/path/to/file]+ | Takes one or more files, training the chain with the contents.         |
| clear      | c     |                  | Clears data from the markov chain, reseting it to its initial state.   |
| crossover  | x     | [chance]         | Crossover rate. Valid values are between 0.0 and 1.0.                  |
| mutation   | m     | [chance]         | Mutation rate. Valid values are between 0.0 and 1.0.                   |
| seed       | s     | [token]+         | Takes one or more tokens, used as the starting output tokens.          |
| generate   | g     | [length]         | Takes a length parameter. Generates that many words of output.         |
| quit       | q     |                  | Exits the program.                                                     |
| db:connect | db:c  | [connect string] | Takes a connection string and connects to a database. |
| db:init    | db:i  |                  | Creates the database tables and structure.            |
| db:destroy | db:d  |                  | Removes tables from database.                         |

### License

The Unlicense.
