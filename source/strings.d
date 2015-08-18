
module strings;

import util;

class String
{
private:
	size_t _id;
	string _text;

	this(size_t id, string text = null)
	{
		_id = id;
		_text = text;
	}

public:
	static String find(size_t id)
	{
		return new String(id);
	}

	static String findOrCreate(string text)
	{
		auto ptr = text in StringTable;

		if(ptr !is null)
		{
			// Return the existing string.
			return new String(*ptr, text);
		}
		else
		{
			// Create a new string and return it.
			return new String(StringTable ~ text, text);
		}
	}

	@property
	size_t id()
	{
		return _id;
	}

	@property
	string value()
	{
		if(_text is null)
		{
			// Resolve string by id.
			_text = StringTable[_id];
		}

		return _text;
	}

	override hash_t toHash()
	{
		return _id;
	}

	override int opCmp(Object o)
	{
		String str = cast(String)o;
		return str && _id - str._id;
	}

	override bool opEquals(Object o)
	{
		String str = cast(String)o;
		return str && str._id == _id;
	}

	override string toString()
	{
		return value;
	}
}

class StringTable
{
private:
	static size_t next;
	static string[size_t] table;
	static size_t[string] lookup;

	static size_t opBinary(string op : "~")(string str)
	{
		lookup[str] = next;
		table[next] = str;
		return next++;
	}

	static string *opBinaryRight(string op : "in")(size_t id)
	{
		return id in table;
	}

	static size_t *opBinaryRight(string op : "in")(string str)
	{
		return str in lookup;
	}

	static string opIndex(size_t id)
	{
		return table[id];
	}

	static size_t opIndex(string str)
	{
		return lookup[str];
	}

public:
	static void clear()
	{
		table.removeAll;
		lookup.removeAll;
	}

	static void optimize()
	{
		table.rehash;
		lookup.rehash;
	}
}
