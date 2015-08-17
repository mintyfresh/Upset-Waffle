
module markov;

import std.algorithm;
import std.array;
import std.exception;
import std.random;
import std.string;
import std.typecons;
import std.typetuple;

import strings;
import counters;

struct Element
{
	StringId token;

	double frequency;

	string toString()
	{
		return "(%s, %s)".format(token, frequency);
	}
}

class FrequencyTable(Keys...)
{
	alias StringIds = Tuple!Keys;

	private StringTable stringTable;

	private CounterTable!Keys counter;
	private Element[][StringIds] table;

	this(StringTable stringTable)
	{
		this.stringTable = stringTable;
		this.counter = new CounterTable!Keys(stringTable);
	}

	@property
	size_t length()
	{
		return table.length;
	}

	void clear()
	{
		counter.clear;

		foreach(key, value; table)
		{
			table.remove(key);
		}
	}
	
	Element[] opIndex(StringIds key)
	{
		auto tablePtr = key in table;
		return tablePtr ? *tablePtr : null;
	}

	StringId random()
	{
		if(table.length < 1) return NullString;

		size_t index = uniform(0L, table.keys.length);
		Element[] elements = this[table.keys[index]];
		if(elements.empty) return NullString;

		index = uniform(0L, elements.length);
		return elements[index].token;
	}

	StringId select(Keys keys)
	{
		StringIds key = StringIds(keys);
		Element[] elements = this[key];
		if(elements.empty) return NullString;

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

		return NullString;
	}

	void train(StringId[] tokens)
	{
		if(tokens.length < Keys.length) return;

		foreach(index, token; tokens[0 .. $ - Keys.length])
		{
			StringIds key;

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
	private StringTable stringTable;

	private double _mutation;
	private double _crossover;

	private StringId[] _seed;

	private FrequencyTable!(StringId) unaryTable;
	private FrequencyTable!(StringId, StringId) binaryTable;
	private FrequencyTable!(StringId, StringId, StringId) ternaryTable;

	this()
	{
		stringTable = new StringTable;
		unaryTable = new FrequencyTable!(StringId)(stringTable);
		binaryTable = new FrequencyTable!(StringId, StringId)(stringTable);
		ternaryTable = new FrequencyTable!(StringId, StringId, StringId)(stringTable);
	}

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
		return _seed.map!((id) {
			return stringTable[id];
		}).array;
	}

	@property
	void seed(string[] tokens)
	{
		_seed = tokens.map!((token) {
			auto ptr = token in stringTable;
			return ptr ? *ptr : stringTable ~ token;
		}).array;
	}

	@property
	size_t stringsLength()
	{
		return stringTable.length;
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
		stringTable.clear;

		// Clear frequency tables.
		unaryTable.clear;
		binaryTable.clear;
		ternaryTable.clear;
	}

	void train(string[] tokens)
	{
		StringId[] ids = tokens.map!((token) {
			auto ptr = token in stringTable;
			return ptr ? *ptr : stringTable ~ token;
		}).array;

		unaryTable.train(ids);
		binaryTable.train(ids);
		ternaryTable.train(ids);
	}

	void build()
	{
		// Optimize string table.
		stringTable.rehash;

		// Build frequency tables.
		unaryTable.build;
		binaryTable.build;
		ternaryTable.build;
	}

	string[] generate(int length)
	{
		StringId[] output;

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
			StringId token;

			if(output.length >= 3)
			{
				auto temp = ternaryTable.select(output[$ - 3], output[$ - 2], output[$ - 1]);
				if(temp.isNull) token = temp;
			}

			// Roll for cross-over.
			if(output.length >= 2 && (token.isNull || uniform(0.0, 1.0) < _crossover))
			{
				auto temp = binaryTable.select(output[$ - 2], output[$ - 1]);
				if(temp.isNull) token = temp;
			}

			// Roll for mutation.
			if(token.isNull || uniform(0.0, 1.0) < _mutation)
			{
				auto temp = unaryTable.select(output[$ - 1]);
				if(temp.isNull) token = temp;
			}

			if(token.isNull)
			{
				token = unaryTable.random;
				enforce(!token.isNull, "No possible tokens.");
			}

			output ~= token;
		}

		return output.map!((id) {
			return stringTable[id];
		}).array;
	}
}
