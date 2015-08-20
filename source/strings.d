
module strings;

version(UseMySQL)
{
	public import database.strings;
}
else
{
	public import memory.strings;
}

class String
{
	private size_t _id;
	private string _text;

	private this(size_t id, string text = null)
	{
		_id = id;
		_text = text;
	}

	static String find(size_t id)
	{
		return new String(id);
	}

	static String findOrCreate(string text)
	{
		auto ptr = text in StringTable.get;

		if(ptr !is null)
		{
			// Return the existing string.
			return new String(*ptr, text);
		}
		else
		{
			// Create a new string and return it.
			return new String(StringTable.get ~ text, text);
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
			_text = StringTable.get[_id];
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

hash_t toHash(String str)
{
	if(str is null) assert(0);
	return str.toHash;
}
