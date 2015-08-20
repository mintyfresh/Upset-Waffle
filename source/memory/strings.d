
module memory.strings;

import util;

class StringTable
{
	private size_t next;
	private string[size_t] table;
	private size_t[string] lookup;

	private static StringTable instance;

	static this()
	{
		instance = new StringTable;
	}

	@property
	static StringTable get()
	{
		return instance;
	}

	void clear()
	{
		table.removeAll;
		lookup.removeAll;
	}

	void optimize()
	{
		table.rehash;
		lookup.rehash;
	}

	size_t opBinary(string op : "~")(string str)
	{
		lookup[str] = next;
		table[next] = str;
		return next++;
	}

	string *opBinaryRight(string op : "in")(size_t id)
	{
		return id in table;
	}

	size_t *opBinaryRight(string op : "in")(string str)
	{
		return str in lookup;
	}

	string opIndex(size_t id)
	{
		return table[id];
	}

	size_t opIndex(string str)
	{
		return lookup[str];
	}
}

