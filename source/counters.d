
module counters;

import std.typecons;

import strings;

class CounterTable(Keys...)
{
	alias StringIds = Tuple!Keys;

	private StringTable stringTable;

	private int[StringIds] totals;
	private int[StringId][StringIds] counts;

	this(StringTable stringTable)
	{
		this.stringTable = stringTable;
	}

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

	ref int opIndex(StringIds key)
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

	ref int opIndex(StringIds key, StringId token)
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

	int opApply(scope int delegate(StringIds, int[StringId]) dg)
	{
		foreach(key, value; counts)
		{
			int result = dg(key, value);
			if(result) return result;
		}

		return 0;
	}
}
