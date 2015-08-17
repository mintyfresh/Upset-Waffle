
module strings;

import std.typetuple;

alias StringId = ulong;
alias NullString = Alias!0;

class StringTable
{
	private StringId next = 1;
	private StringId[string] idTable;
	private string[StringId] stringTable;

	@property
	size_t length()
	{
		return stringTable.length;
	}

	void rehash()
	{
		idTable.rehash;
		stringTable.rehash;
	}

	void clear()
	{
		foreach(key, value; stringTable)
		{
			stringTable.remove(key);
		}

		foreach(key, value; idTable)
		{
			idTable.remove(key);
		}
	}

	StringId opBinary(string op : "~")(string str)
	{
		return stringTable[next] = str, idTable[str] = next, next++;
	}

	string *opBinaryRight(string op : "in")(StringId stringId)
	{
		return stringId in stringTable;
	}

	bool opBinaryRight(string op : "!in")(StringId stringId)
	{
		return stringId !in stringTable;
	}

	StringId *opBinaryRight(string op : "in")(string str)
	{
		return str in idTable;
	}

	bool opBinaryRight(string op : "!in")(string str)
	{
		return str !in idTable;
	}

	string opIndex(StringId stringId)
	{
		return stringTable[stringId];
	}

	StringId opIndex(string str)
	{
		return idTable[str];
	}

	StringId opOpAssign(string op : "~")(string str)
	{
		return this ~ str;
	}
}

bool isNull(StringId stringId)
{
	return stringId == NullString;
}
