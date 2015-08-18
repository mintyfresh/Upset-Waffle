
module repl;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.exception;
import std.range;
import std.stdio;
import std.string;

import markov;

void parse(Markov markov)
{
	while(true)
	{
		// Handle multiple commands per line.
		string[] commands = readln.split("&&");

		foreach(command; commands)
		{
			// Tokenize and parse the command.
			if(!parseCommand(markov, command.strip.split))
			{
				return;
			}
		}

		writeln;
	}
}

bool parseCommand(Markov markov, string[] tokens)
{
	if(tokens.empty) return true;

	switch(tokens[0])
	{
		case "e":
		case "exit":
		{
			"Done.".writeln;

			return false;
		}
		case "c":
		case "clear":
		{
			markov.clear;
			"Cleared state.".writeln;

			return true;
		}
		case "m":
		case "mutation":
		{
			if(tokens.length > 1)
			{
				markov.mutation = tokens[1].to!double;
			}

			"Mutation rate: %s".writefln(markov.mutation);

			return true;
		}
		case "x":
		case "crossover":
		{
			if(tokens.length > 1)
			{
				markov.crossover = tokens[1].to!double;
			}

			"Crossover rate: %s".writefln(markov.crossover);

			return true;
		}
		case "s":
		case "seed":
		{
			if(tokens.length > 1)
			{
				markov.seed = tokens[1 .. $];
			}

			"Seed: %(%s, %)".writefln(markov.seed);

			return true;
		}
		case "t":
		case "train":
		{
			int failCount = 0;
			int successCount = 0;
			ulong totalTime = 0;

			if(tokens.length < 2)
			{
				"Syntax:".writeln;
				"train [/path/to/file]+".writeln;

				return true;
			}

			foreach(filename; tokens[1 .. $])
			{
				ulong time;
				StopWatch watch;

				try
				{
					// Start a benchmark.
					watch.start();
					auto file = File(filename, "r");

					// Train the chain from the file contents.
					markov.train(
						file
						.byLine
						.map!text
						.map!splitter
						.joiner
					);

					// Display file time.
					watch.stop();
					totalTime += time = watch.peek.msecs;
					"Trained (%dms): `%s`.".writefln(time, filename);
					watch.reset();

					// Track successes.
					successCount++;
				}
				catch(ErrnoException ex)
				{
					"Couldn't read file `%s`.".writefln(filename);

					// Track failures.
					failCount++;
				}
			}

			// Display train time and success/failure rates.
			"Finished (%dms): Trained from %d files, %d files failed.".writefln(
				totalTime, successCount, failCount
			);

			return true;
		}
		case "b":
		case "build":
		{
			StopWatch watch;

			// Track build times.
			watch.start();
			markov.build;
			watch.stop();

			// Display build time and table sizes.
			"Finished(%dms): Tables %d, %d, %d.".writefln(
				watch.peek.msecs,
				markov.unaryLength,
				markov.binaryLength,
				markov.ternaryLength
			);

			return true;
		}
		case "g":
		case "generate":
		{
			if(tokens.length < 2)
			{
				"Syntax:".writeln;
				"generate [length]".writeln;

				return true;
			}

			markov
				.generate(tokens[1].to!int)
				.joiner(" ")
				.writeln;

			return true;
		}
		default:
		{
			"Unknown command: %s".writefln(tokens[0]);

			return true;
		}
	}
}
