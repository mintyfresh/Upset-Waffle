
module counters;

import strings;
import util;

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
	 + Stores a counter's totals and frequencies.
	 ++/
	private struct Counter
	{
		/++
		 + The sequence this counter is bound to.
		 ++/
		Strings sequence;

		/++
		 + The total number of occurrences of the sequence.
		 ++/
		size_t total;

		/++
		 + Frequency table indexed by following tokens.
		 ++/
		Frequency[String] tokens;
	}

	/++
	 + Stores a frequency's occurrences.
	 ++/
	private struct Frequency
	{
		/++
		 + The token this frequency is bound to.
		 ++/
		String token;

		/++
		 + The frequency with which this token occurs.
		 ++/
		size_t occurrences;
	}

	/++
	 + Provides an interface for safely operating on counters.
	 ++/
	struct CounterRef
	{
		/++
		 + Stores a pointer to a counter in the counter table.
		 ++/
		private Counter *counter;

		/++
		 + Alias the counter total to this.
		 ++/
		alias total this;

		/++
		 + Hidden constructor used to issue counter references.
		 ++/
		private this(Counter *counter)
		{
			this.counter = counter;
		}

		/++
		 + Checks if the counter's frequency table is empty.
		 ++/
		@property
		bool empty()
		{
			return length < 1;
		}

		/++
		 + Returns the number of elements in the counter.
		 ++/
		@property
		size_t length()
		{
			return counter.tokens.length;
		}

		/++
		 + Returns the sequence that the counter is bound to.
		 ++/
		@property
		Strings sequence()
		{
			return counter.sequence;
		}

		/++
		 + Returns the number of occurrences of the counter's sequence.
		 ++/
		@property
		size_t total()
		{
			return counter.total;
		}

		/++
		 + Iterates over the frequencies of this counter.
		 ++/
		int opApply(scope int delegate(FrequencyRef) dg)
		{
			foreach(key, value; counter.tokens)
			{
				int result = dg(FrequencyRef(&this, &value));
				if(result) return result;
			}

			return 0;
		}

		/++
		 + Returns the token at the given frequency index.
		 ++/
		String opIndex(size_t index)
		{
			return counter.tokens.keys[index];
		}

		/++
		 + Returns a reference to the frequency of a token.
		 ++/
		FrequencyRef opIndex(String token)
		{
			auto ptr = token in counter.tokens;

			if(ptr !is null)
			{
				// Issue a frequency reference.
				return FrequencyRef(&this, ptr);
			}
			else
			{
				// Create a frequency for the new token.
				counter.tokens[token] = Frequency(token);
				return FrequencyRef(&this, &counter.tokens[token]);
			}
		}
	}

	struct FrequencyRef
	{
		/++
		 + The counter reference that issued this frequency reference.
		 ++/
		private CounterRef *counter;

		/++
		 + Stores a pointer to a frequency in the frequency table.
		 ++/
		private Frequency *frequency;

		/++
		 + Alias the frequency's occurrences to this.
		 ++/
		alias occurrences this;

		/++
		 + Hide the constructor used to issue frequency references.
		 ++/
		this(CounterRef *counter, Frequency *frequency)
		{
			this.counter = counter;
			this.frequency = frequency;
		}

		/++
		 + Returns the token's number of occurrences.
		 ++/
		@property
		size_t occurrences()
		{
			return frequency.occurrences;
		}

		/++
		 + Returns the sequence that the token follows.
		 ++/
		@property
		Strings sequence()
		{
			return counter.sequence;
		}

		/++
		 + Returns the token the frequency is bound to.
		 ++/
		@property
		String token()
		{
			return frequency.token;
		}

		/++
		 + Returns the total number of occurrences of the sequence.
		 ++/
		@property
		size_t total()
		{
			return counter.total;
		}

		/++
		 + Increments the token's number of occurrences.
		 ++/
		size_t opUnary(string op : "++")()
		{
			counter.counter.total++;
			return frequency.occurrences++;
		}

		/++
		 + Decrements the token's number of occurrences.
		 ++/
		size_t opUnary(string op : "--")()
		{
			counter.counter.total--;
			return frequency.occurrences--;
		}
	}

	/++
	 + A table for frequency counters, indexed by sequences.
	 ++/
	private Counter[Strings] table;

	/++
	 + Checks if the counter table is empty.
	 ++/
	@property
	bool empty()
	{
		return length < 1;
	}

	/++
	 + Returns the number of entries in the counter table.
	 ++/
	@property
	size_t length()
	{
		return table.length;
	}

	/++
	 + Clears all counters from the table.
	 ++/
	void clear()
	{
		table.removeAll;
	}

	/++
	 + Optimizes the table's indexes.
	 ++/
	void optimize()
	{
		table.rehash;
	}

	/++
	 + Returns a counter reference at the given index.
	 ++/
	CounterRef opIndex(size_t index)
	{
		return this[table.keys[index]];
	}

	/++
	 + Returns a counter reference at the given sequence.
	 ++/
	CounterRef opIndex(Strings sequence)
	{
		auto ptr = sequence in table;

		if(ptr !is null)
		{
			// Return a ref.
			return CounterRef(ptr);
		}
		else
		{
			// Initialize and return a ref.
			table[sequence] = Counter(sequence, 0);
			return CounterRef(&table[sequence]);
		}
	}
}
