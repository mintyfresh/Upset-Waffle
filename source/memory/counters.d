
module memory.counters;

import std.algorithm;
import std.array;
import std.random;

import strings;
import util;

struct Frequency
{
	String token;
	size_t occurrences;
}

/++
 + Tracks occurrences of tokens after sequences of the template length.
 ++/
struct CounterTable(int Count)
{
	/++
	 + Defines a type that is a sequence of strings.
	 ++/
	alias Strings = String[Count];

	/++
	 + A table for frequency counters, indexed by sequences.
	 ++/
	private size_t[String][Strings] table;

	/++
	 + Clears all counters from the table.
	 ++/
	void clear()
	{
		table.removeAll;
	}

	/++
	 + Checks if the counter table is empty.
	 ++/
	@property
	bool empty()
	{
		return length < 1;
	}

	Frequency get(Strings sequence, String token)
	{
		return Frequency(token, table[sequence][token]);
	}

	/++
	 + Returns the number of entries in the counter table.
	 ++/
	@property
	size_t length()
	{
		return table.length;
	}

	Frequency[] list(Strings sequence)
	{
		auto ptr = sequence in table;
		if(ptr is null) return null;

		return (*ptr)
			.byKeyValue
			.map!(element =>
				Frequency(
					element.key,
					element.value
				)
			)
			.array;
	}

	String random()
	{
		size_t index = uniform(0, table.length);
		auto frequency = table.values[index];

		index = uniform(0, frequency.length);
		return frequency.keys[index];
	}

	void set(Strings sequence, String token)
	{
		auto tablePtr = sequence in table;

		if(tablePtr !is null)
		{
			auto frequencyPtr = token in (*tablePtr);

			if(frequencyPtr !is null)
			{
				// Increment occurrences.
				(*frequencyPtr)++;
			}
			else
			{
				// Initialize the token.
				(*tablePtr)[token] = 1;
			}
		}
		else
		{
			// Initialize both indexes.
			table[sequence] = [token: 1];
		}
	}
}
