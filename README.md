Upset Waffle
============

A markov chain powered text generator, written in D. Ships with a simple REPL.

### How-To

Compile and run.

`dmd source/*.d`

### The REPL

Commands:

 - `train [file]` : Takes an absolute path to an input file, and train the markov chain using the contents.

 - `build` : Builds or rebuilds the frequency tables. Run after training the chain.

 - `crossover [chance]` : Takes a value for the crossover rate; valid values are between `0.0` and `1.0`. Use `0.2` for best results.

 - `mutation [chance]` : Takes a value for the mutation rate; valid values are between `0.0` and `1.0`. Using `0.1` for best results.

 - `seed [text]` : Takes an (unquoted) string as the initial seed for the text.

 - `generate [length]` : Takes a length parameter. Produces that many words of output.

 - `exit` : Exits the program.

### License

The Unlicense.
