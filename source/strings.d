
module strings;

import util;

class String
{
	size_t _id;
	string _text;

	private this(size_t id, string text)
	{
		_id = id;
		_text = text;
	}

	static String find(size_t id)
	{
		auto tablePtr = id in StringTable;

		if(tablePtr !is null)
		{
			return new String(id, *tablePtr);
		}
		else
		{
			return null;
		}
	}

	static String findOrCreate(string text)
	{
		auto tablePtr = text in StringTable;

		if(tablePtr !is null)
		{
			return new String(*tablePtr, text);
		}
		else
		{
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
			// Resolve the string reference.
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
