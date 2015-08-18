
module counters;

import std.typecons;

import strings;
import util;

struct CounterTable(Keys...)
{
	alias Strings = Tuple!Keys;

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

	ref int opIndex(Strings key)
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

	ref int opIndex(Strings key, String token)
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

	int opApply(scope int delegate(Strings, int[String]) dg)
	{
		foreach(key, value; counts)
		{
			int result = dg(key, value);
			if(result) return result;
		}

		return 0;
	}
}
