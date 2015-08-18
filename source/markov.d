
module markov;

import std.algorithm;
import std.array;
import std.exception;
import std.random;
import std.string;
import std.typecons;
import std.typetuple;

import counters;
import strings;
import util;

struct Element
{
	String token;

	double frequency;

	string toString()
	{
		return "(%s, %s)".format(token, frequency);
	}
}

struct MarkovState(int Count)
{
private:
	alias Keys = TemplateSequence!(Count, String);
	alias Strings = Tuple!Keys;

	CounterTable!Keys counter;
	Element[][Strings] table;

public:
	@property
	size_t length()
	{
		return table.length;
	}

	void clear()
	{
		counter.clear;
		table.removeAll;
	}
	
	Element[] opIndex(Strings key)
	{
		return table.get(key, null);
	}

	String random()
	{
		if(table.length < 1) return null;

		size_t index = uniform(0L, table.keys.length);
		Element[] elements = this[table.keys[index]];
		if(elements.empty) return null;

		index = uniform(0L, elements.length);
		return elements[index].token;
	}

	String select(String[] keys...)
	{
		String[Count] array = keys;
		return select(Strings(array));
	}

	String select(Keys keys)
	{
		return select(Strings(keys));
	}

	String select(Strings keys)
	{
		double value = uniform(0.0, 1.0);

		foreach(element; this[keys])
		{
			if(value < element.frequency)
			{
				return element.token;
			}
			else
			{
				value -= element.frequency;
			}
		}

		return null;
	}

	void train(String[] tokens)
	{
		// Input text too short, skip.
		if(tokens.length < Count) return;

		// Iterate over sequences of tokens.
		foreach(index, token; tokens[0 .. $ - Count])
		{
			String[Count] array = tokens[index .. index + Count];
			Strings key = Strings(array);

			counter[key, tokens[index + Count]]++;
			counter[key]++;
		}
	}

	void build()
	{
		// Improve performance.
		counter.optimize;

		// Iterate over counters.
		foreach(index, count; counter)
		{
			int total = counter[index];

			foreach(token, value; count)
			{
				double frequency = value * 1.0 / (total ? total : 1.0);
				table[index] ~= Element(token, frequency);
			}
		}
	}
}

class Markov
{
private:
	double _mutation;
	double _crossover;

	String[] _seed;

	MarkovState!1 unaryTable;
	MarkovState!2 binaryTable;
	MarkovState!3 ternaryTable;

public:
	@property
	double mutation()
	{
		return _mutation;
	}

	@property
	void mutation(double mutation)
	{
		_mutation = mutation;
	}

	@property
	double crossover()
	{
		return _crossover;
	}

	@property
	void crossover(double crossover)
	{
		_crossover = crossover;
	}

	@property
	string[] seed()
	{
		return _seed
			.map!(str => str.toString)
			.array;
	}

	@property
	void seed(string[] tokens)
	{
		_seed = tokens
			.filter!(token => token.length > 0)
			.map!(token => String.findOrCreate(token))
			.array;
	}

	@property
	size_t unaryLength()
	{
		return unaryTable.length;
	}

	@property
	size_t binaryLength()
	{
		return binaryTable.length;
	}

	@property
	size_t ternaryLength()
	{
		return ternaryTable.length;
	}

	void clear()
	{
		// Clear string table.
		StringTable.get.clear;

		// Clear frequency tables.
		unaryTable.clear;
		binaryTable.clear;
		ternaryTable.clear;
	}

	void train(Range)(Range tokens)
	{
		// Map to string references.
		String[] strings = tokens
			.filter!(token => token.length > 0)
			.map!(token => String.findOrCreate(token))
			.array;

		// Rehash string table.
		StringTable.get.optimize;

		// Train frequency tables.
		unaryTable.train(strings);
		binaryTable.train(strings);
		ternaryTable.train(strings);
	}

	void build()
	{
		// Build frequency tables.
		unaryTable.build;
		binaryTable.build;
		ternaryTable.build;
	}

	auto generate(int length)
	{
		String[] output;

		// Starting tokens.
		if(_seed.length > 0)
		{
			output ~= _seed;
		}

		while(output.length < length)
		{
			String token;

			if(output.length >= 3)
			{
				auto temp = ternaryTable.select(output[$ - 3 .. $]);
				if(temp !is null) token = temp;
			}

			// Roll for two-token sequence crossover change.
			if(output.length >= 2 && (token is null || uniform(0.0, 1.0) < _crossover))
			{
				auto temp = binaryTable.select(output[$ - 2 .. $]);
				if(temp !is null) token = temp;
			}

			// Roll for single-token sequence crossover chance.
			if(output.length >= 1 && (token is null || uniform(0.0, 1.0) < _crossover / 2))
			{
				auto temp = unaryTable.select(output[$ - 1 .. $]);
				if(temp !is null) token = temp;
			}

			// Roll for random token mutation chance.
			if(token is null || uniform(0.0, 1.0) < _mutation)
			{
				auto temp = unaryTable.random;
				if(temp !is null) token = temp;
			}

			// Append resulting token to the output list.
			enforce(token !is null, "No possible tokens.");
			output ~= token;
		}

		return output
			.map!(str => str.toString)
			.filter!(str => str.length > 0);
	}
}
