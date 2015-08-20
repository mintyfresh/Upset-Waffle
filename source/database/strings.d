
module database.strings;

version(UseMySQL):

import std.string;

import database.connection;

@property
private Connection cn()
{
	return ConnectionManager.get.connection;
}

class StringTable
{
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
		cn.exec("
			TRUNCATE strings
		");
	}

	void create()
	{
		cn.exec("
			CREATE TABLE `strings`
			(
				`id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
				`value` MEDIUMTEXT NOT NULL,

				PRIMARY KEY(`id`),
				INDEX(`value`(255)),
				UNIQUE KEY `unique_strings_key`(`value`(255))
			)
			ENGINE=InnoDB
			AUTO_INCREMENT=0
			DEFAULT CHARSET=utf8;
		");
	}

	void destroy()
	{
		cn.exec("
			DROP TABLE IF EXISTS `strings`;
		");
	}

	void optimize()
	{
		// Nothing.
	}

	size_t opBinary(string op : "~")(string str)
	{
		auto ptr = str in this;

		if(ptr !is null)
		{
			return *ptr;
		}
		else
		{
			auto rows = cn.exec("
				INSERT INTO `strings`(`value`)
				VALUES('%s');
			".format(
				str.escape
			));

			return cn.querySingle("
				SELECT LAST_INSERT_ID();
			")[0]
			.coerce!size_t;
		}
	}

	size_t *opBinaryRight(string op : "in")(string str)
	{
		auto rows = cn.query("
			SELECT `id`
			FROM `strings`
			WHERE `value`='%s';
		".format(
			str.escape
		));

		if(rows.length > 0)
		{
			size_t *ptr = new size_t;
			*ptr = rows[0][0].coerce!size_t;
			return ptr;
		}
		else
		{
			return null;
		}
	}

	string opIndex(size_t id)
	{
		return cn.querySingle("
			SELECT `value`
			FROM `strings`
			WHERE `id`=%d;
		".format(
			id
		))[0]
		.get!string;
	}

	size_t opIndex(string str)
	{
		return cn.querySingle("
			SELECT `id`
			FROM `strings`
			WHERE `value`='%s';
		".format(
			str.escape
		))[0]
		.coerce!size_t;
	}
}


