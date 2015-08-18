
module counters;

import strings;
import util;

struct CounterTable(int Count)
{
	alias Strings = String[Count];

	private int[Strings] totals;
	private int[String][Strings] counts;

	void clear()
	{
		totals.removeAll;
		counts.removeAll;
	}

	void optimize()
	{
		totals.rehash;
		counts.rehash;
	}

	ref int opIndex(Strings sequence)
	{
		auto totalsPtr = sequence in totals;

		if(totalsPtr !is null)
		{
			return *totalsPtr;
		}
		else
		{
			totals[sequence] = 0;
			return totals[sequence];
		}
	}

	ref int opIndex(Strings sequence, String token)
	{
		auto countsPtr = sequence in counts;

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
			counts[sequence] = [token: 0];
			return counts[sequence][token];
		}
	}

	int opApply(scope int delegate(Strings, int[String]) dg)
	{
		foreach(sequence, token; counts)
		{
			int result = dg(sequence, token);
			if(result) return result;
		}

		return 0;
	}
}
