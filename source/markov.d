
module markov;

import std.random;
import std.string;
import std.typecons;

struct Element
{
	string token;

	double frequency;

	string toString()
	{
		return "(%s, %s)".format(token, frequency);
	}
}

struct CounterTable(Keys...)
{
	alias KeyType = Tuple!Keys;

	int[KeyType] totals;
	int[string][KeyType] counts;

	void clear()
	{
		foreach(key, value; totals)
		{
			totals.remove(key);
		}

		foreach(key, value; counts)
		{
			counts.remove(key);
		}
	}

	ref int opIndex(KeyType key)
	{
		auto totalsPtr = key in totals;

		if(totalsPtr !is null)
		{
			return *totalsPtr;
		}
		else
		{
			totals[key] = 0;
			return totals[key];
		}
	}

	ref int opIndex(KeyType key, string token)
	{
		auto countsPtr = key in counts;

		if(countsPtr !is null)
		{
			auto tokens = *countsPtr;
			auto tokensPtr = token in tokens;

			if(tokensPtr !is null)
			{
				return *tokensPtr;
			}
			else
			{
				tokens[token] = 0;
				return tokens[token];
			}
		}
		else
		{
			counts[key] = [token: 0];
			return counts[key][token];
		}
	}

}

struct FrequencyTable(Keys...)
{
	alias KeyType = Tuple!Keys;

	CounterTable!Keys counter;
	Element[][KeyType] table;

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
	
	Element[] opIndex(KeyType key)
	{
		auto tablePtr = key in table;
		return tablePtr ? *tablePtr : null;
	}

	string random()
	{
		if(table.length < 1) return null;

		size_t index = uniform(0L, table.keys.length);
		Element[] elements = this[table.keys[index]];
		if(elements.length < 1) return null;

		index = uniform(0L, elements.length);
		return elements[index].token;
	}

	string select(Keys keys)
	{
		KeyType key = KeyType(keys);
		Element[] elements = this[key];
		if(elements.length == 0) return null;

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

	void train(string[] tokens)
	{
		if(tokens.length < Keys.length) return;

		foreach(index, token; tokens[0 .. $ - Keys.length])
		{
			KeyType key;

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

			string next = tokens[index + Keys.length];

			counter[key, next]++;
			counter[key]++;
		}
	}

	void build()
	{
		foreach(index, count; counter.counts)
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
	double _mutation;
	double _crossover;

	string[] _seed;

	FrequencyTable!(string) unaryTable;
	FrequencyTable!(string, string) binaryTable;
	FrequencyTable!(string, string, string) ternaryTable;

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
		return _seed;
	}

	@property
	void seed(string[] seed)
	{
		_seed = seed;
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
		unaryTable.clear;
		binaryTable.clear;
		ternaryTable.clear;
	}

	void train(string[] tokens)
	{
		unaryTable.train(tokens);
		binaryTable.train(tokens);
		ternaryTable.train(tokens);
	}

	void build()
	{
		unaryTable.build;
		binaryTable.build;
		ternaryTable.build;
	}

	string[] generate(int length)
	{
		string[] output;

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
			string token = null;

			if(output.length >= 3)
			{
				string temp = ternaryTable.select(output[$ - 3], output[$ - 2], output[$ - 1]);
				if(temp !is null) token = temp;
			}

			// Roll for cross-over.
			if(output.length >= 2 && (token is null || uniform(0.0, 1.0) < _crossover))
			{
				string temp = binaryTable.select(output[$ - 2], output[$ - 1]);
				if(temp !is null) token = temp;
			}

			// Roll for mutation.
			if(token is null || uniform(0.0, 1.0) < _mutation)
			{
				string temp = unaryTable.select(output[$ - 1]);
				if(temp !is null) token = temp;
			}

			if(token is null)
			{
				token = unaryTable.random;
				if(token is null) assert(0);
			}

			output ~= token;
		}

		return output;
	}
}
