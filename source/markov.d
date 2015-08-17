
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

struct FrequencyTable(Keys...)
{
	alias Strings = Tuple!Keys;

	private CounterTable!Keys counter;
	private Element[][Strings] table;

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
		auto tablePtr = key in table;
		return tablePtr ? *tablePtr : null;
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

	String select(Keys keys)
	{
		Strings key = Strings(keys);
		Element[] elements = this[key];
		if(elements.empty) return null;

		double value = uniform(0.0, 1.0);

		foreach(element; elements)
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
		if(tokens.length < Keys.length) return;

		foreach(index, token; tokens[0 .. $ - Keys.length])
		{
			Strings key;

			string generateAssignments()
			{
				string output;
				foreach(pos; 0 .. Keys.length)
				{
					output ~= "key[%1$d] = tokens[index + %1$d];".format(pos);
				}
				return output;
			}

			mixin(generateAssignments);

			counter[key, tokens[index + Keys.length]]++;
			counter[key]++;
		}
	}

	void build()
	{
		foreach(index, count; counter)
		{
			int total = counter[index];

			foreach(token, value; count)
			{
				double frequency = value * 1.0 / (total ? total : 1.0);
				table[index] ~= Element(token, frequency);
			}
		}

		// Rehash for performance.
		table.rehash;
	}
}

class Markov
{
	private double _mutation;
	private double _crossover;

	private String[] _seed;

	private FrequencyTable!(String) unaryTable;
	private FrequencyTable!(String, String) binaryTable;
	private FrequencyTable!(String, String, String) ternaryTable;

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
		StringTable.clear;

		// Clear frequency tables.
		unaryTable.clear;
		binaryTable.clear;
		ternaryTable.clear;
	}

	void train(string[] tokens)
	{
		// Map to string references.
		String[] strings = tokens
			.map!(token => String.findOrCreate(token))
			.array;

		// Train frequency tables.
		unaryTable.train(strings);
		binaryTable.train(strings);
		ternaryTable.train(strings);
	}

	void build()
	{
		// Rehash string table.
		StringTable.optimize;

		// Build frequency tables.
		unaryTable.build;
		binaryTable.build;
		ternaryTable.build;
	}

	string[] generate(int length)
	{
		String[] output;

		// Starting tokens.
		if(_seed.length > 0)
		{
			output ~= _seed;
		}
		else
		{
			output ~= unaryTable.random;
		}

		while(output.length < length)
		{
			String token;

			if(output.length >= 3)
			{
				auto temp = ternaryTable.select(output[$ - 3], output[$ - 2], output[$ - 1]);
				if(temp !is null) token = temp;
			}

			// Roll for cross-over.
			if(output.length >= 2 && (token is null || uniform(0.0, 1.0) < _crossover))
			{
				auto temp = binaryTable.select(output[$ - 2], output[$ - 1]);
				if(temp !is null) token = temp;
			}

			// Roll for mutation.
			if(token is null || uniform(0.0, 1.0) < _mutation)
			{
				auto temp = unaryTable.select(output[$ - 1]);
				if(temp !is null) token = temp;
			}

			if(token is null)
			{
				token = unaryTable.random;
				enforce(token !is null, "No possible tokens.");
			}

			output ~= token;
		}

		return output
			.map!(str => str.toString)
			.array;
	}
}
