
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
		 + The frequency with which this token occurs.
		 ++/
		size_t occurrences;
	}

	/++
	 + Provides an interface for safely operating on counters.
	 ++/
	class CounterRef
	{
		/++
		 + The counter table that issued this counter reference.
		 ++/
		private CounterTable!Count *_table;

		/++
		 + Stores a pointer to a counter in the counter table.
		 ++/
		private Counter *_counter;

		/++
		 + The sequence the counter is bound to.
		 ++/
		private Strings _sequence;

		/++
		 + Hidden constructor used to issue counter references.
		 ++/
		private this(CounterTable!Count *table, Counter *counter, Strings sequence)
		{
			_table = table;
			_counter = counter;
			_sequence = sequence;
		}

		/++
		 + Creates a counter entry in the table for this reference.
		 ++/
		private void initialize()
		{
			// Create the counter in the table.
			_counter = _table.create(_sequence);
		}

		/++
		 + Creates a frequency entry at the given following token.
		 ++/
		private Frequency *create(String token)
		{
			// Initialize the counter now.
			if(_counter is null) initialize;

			_counter.tokens[token] = Frequency(0);
			return &_counter.tokens[token];
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
			return _counter ? _counter.tokens.length : 0;
		}

		/++
		 + Returns the sequence that the counter is bound to.
		 ++/
		@property
		Strings sequence()
		{
			return _sequence;
		}

		/++
		 + Returns the number of occurrences of the counter's sequence.
		 ++/
		@property
		size_t total()
		{
			return _counter ? _counter.total : 0;
		}

		/++
		 + Iterates over the frequencies of this counter.
		 ++/
		int opApply(scope int delegate(FrequencyRef) dg)
		{
			if(_counter !is null)
			{
				// Allocate a frequency reference ahead of time.
				FrequencyRef frequency = new FrequencyRef(this, null, null);

				// Iterate over the counter's frequencies.
				foreach(key, value; _counter.tokens)
				{
					// Inject current iteration values.
					frequency._frequency = &value;
					frequency._token = key;

					int result = dg(frequency);
					if(result) return result;
				}
			}

			return 0;
		}

		/++
		 + Returns the token at the given frequency index.
		 ++/
		String opIndex(size_t index)
		{
			return _counter ? _counter.tokens.keys[index] : null;
		}

		/++
		 + Returns a reference to the frequency of a token.
		 ++/
		FrequencyRef opIndex(String token)
		{
			if(_counter !is null)
			{
				auto ptr = token in _counter.tokens;

				if(ptr !is null)
				{
					// Issue a frequency reference.
					return new FrequencyRef(this, ptr, token);
				}
			}
			
			// Issue a lazy frequency reference.
			return new FrequencyRef(this, null, token);
		}
	}

	/++
	 + Provides an interface for safely operating on frequencies.
	 ++/
	class FrequencyRef
	{
		/++
		 + The counter reference that issued this frequency reference.
		 ++/
		private CounterRef _counter;

		/++
		 + Stores a pointer to a frequency in the frequency table.
		 ++/
		private Frequency *_frequency;

		/++
		 + The token the frequency is bound to.
		 ++/
		private String _token;

		/++
		 + Alias the frequency's occurrences to this.
		 ++/
		alias occurrences this;

		/++
		 + Hide the constructor used to issue frequency references.
		 ++/
		this(CounterRef counter, Frequency *frequency, String token)
		{
			_counter = counter;
			_frequency = frequency;
			_token = token;
		}

		/++
		 + Creates a frequency entry in the table for this reference.
		 ++/
		private void initialize()
		{
			// Create the frequency in the counter.
			_frequency = _counter.create(_token);
		}

		/++
		 + Returns the token's number of occurrences.
		 ++/
		@property
		size_t occurrences()
		{
			return _frequency ? _frequency.occurrences : 0;
		}

		/++
		 + Returns the sequence that the token follows.
		 ++/
		@property
		Strings sequence()
		{
			return _counter.sequence;
		}

		/++
		 + Returns the token the frequency is bound to.
		 ++/
		@property
		String token()
		{
			return _token;
		}

		/++
		 + Returns the total number of occurrences of the sequence.
		 ++/
		@property
		size_t total()
		{
			return _counter.total;
		}

		/++
		 + Increments the token's number of occurrences.
		 ++/
		size_t opUnary(string op : "++")()
		{
			// Initialize the frequency now.
			if(_frequency is null) initialize;

			_counter._counter.total++;
			return _frequency.occurrences++;
		}
	}

	/++
	 + A table for frequency counters, indexed by sequences.
	 ++/
	private Counter[Strings] table;

	/++
	 + Creates a counter entry at the given sequence.
	 ++/
	private Counter *create(Strings sequence)
	{
		table[sequence] = Counter(0);
		return &table[sequence];
	}

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
			// Return an existing ref.
			return new CounterRef(&this, ptr, sequence);
		}
		else
		{
			// Lazily initialize a ref.
			return new CounterRef(&this, null, sequence);
		}
	}

	/++
	 + Convinience operator to fetch a frequency reference.
	 ++/
	FrequencyRef opIndex(Strings sequence, String token)
	{
		return this[sequence][token];
	}
}
