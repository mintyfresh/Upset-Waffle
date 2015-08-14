
module repl;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;

import markov;

string[] joinify(ByLine)(ByLine lines)
{
	string[] chunk;
	string[] output;

	foreach(line; lines)
	{
		if(line.length > 0)
		{
			chunk ~= line.to!string;
		}
		else
		{
			if(chunk.length > 0)
			{
				output ~= chunk.joiner(" ").text;
				chunk = [ ];
			}
		}
	}

	if(chunk.length > 0)
	{
		output ~= chunk.joiner(" ").text;
	}

	return output;
}

string[] parseFile(File file)
{
	return file.byLine.joinify;
}

void parse(Markov markov)
{
	while(markov.parseCommand(readln.split))
	{
		writeln;
	}
}

bool parseCommand(Markov markov, string[] tokens)
{
	if(tokens.empty) return true;

	switch(tokens[0])
	{
		case "exit":
		{
			"Done.".writeln;

			return false;
		}
		case "clear":
		{
			markov.clear;
			"Cleared state.".writeln;

			return true;
		}
		case "mutation":
		{
			if(tokens.length > 1)
			{
				markov.mutation = tokens[1].to!double;
			}

			"Mutation rate: %s".writefln(markov.mutation);

			return true;
		}
		case "crossover":
		{
			if(tokens.length > 1)
			{
				markov.crossover = tokens[1].to!double;
			}

			"Crossover rate: %s".writefln(markov.crossover);

			return true;
		}
		case "seed":
		{
			if(tokens.length > 1)
			{
				markov.seed = tokens[1 .. $];
			}

			"Seed: %(%s, %)".writefln(markov.seed);

			return true;
		}
		case "train":
		{
			auto file = File(tokens[1], "r");

			foreach(paragraph; file.parseFile)
			{
				markov.train(paragraph.split);
			}

			"File %s".writefln(tokens[1]);

			return true;
		}
		case "build":
		{
			markov.build;
			"Tables %d, %d, %d".writefln(
				markov.unaryLength,
				markov.binaryLength,
				markov.ternaryLength
			);

			return true;
		}
		case "generate":
		{
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
