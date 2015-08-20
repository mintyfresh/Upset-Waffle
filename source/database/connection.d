
module database.connection;

version(UseMySQL):

public import mysql;

class ConnectionManager
{
	private Connection _connection;

	private static ConnectionManager _instance;

	static this()
	{
		_instance = new ConnectionManager();
	}

	private this()
	{
	}

	@property
	static ConnectionManager get()
	{
		return _instance;
	}

	@property
	Connection connection()
	{
		return _connection;
	}

	void connect(string connString)
	{
		_connection = new Connection(connString);
	}
}

ulong exec(Connection cn, string query)
{
	auto cmd = Command(cn);
	cmd.sql = query;

	ulong results;
	cmd.execSQL(results);
	return results;
}

ResultSet query()(Connection cn, string query)
{
	auto cmd = Command(cn);
	cmd.sql = query;

	return cmd.execSQLResult();
}

ResultSet query(Params...)(Connection cn, string query, ref Params params)
{
	auto cmd = cn.prepare(query);
	cmd.bindAll(params);
	return cmd.query();
}

Row querySingle()(Connection cn, string query)
{
	return cn.query(query)[0];
}

string escape(string input)
{
	import std.regex : ctRegex, replaceAll;
	return input.replaceAll(ctRegex!("['\"\\%_]"), "\\$&");
}
