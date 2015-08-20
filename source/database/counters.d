
module database.counters;

version(UseMySQL):

import std.algorithm;
import std.array;
import std.range;
import std.string;
import std.typecons;

import strings;
import util;

import database.connection;

struct Frequency
{
	String token;
	size_t occurrences;
}

struct CounterTable(int Count)
{
	alias Strings = String[Count];

	@property
	private enum tableName = getTableName!Count;

	@property
	private enum tableKeys = getTableKeys!Count;

	void clear()
	{
		cn.exec("
			TRUNCATE `%s`;
		".format(
			tableName
		));
	}

	void create()
	{
		cn.exec("
			CREATE TABLE `%s`
			(
				%-(%s, %),
				`token_id` INT UNSIGNED NOT NULL,
				`occurrences` INT UNSIGNED NOT NULL DEFAULT 0,

				INDEX(`token_id`),
				INDEX(%-(%s, %)),
				UNIQUE KEY `unique_%s_key` (%-(%s, %), `token_id`),

				%-(%s, %),
				FOREIGN KEY(`token_id`)
					REFERENCES `strings`(`id`)
					ON DELETE CASCADE
			)
			ENGINE=InnoDB;
		".format(
			tableName,
			tableKeys.map!(key =>
				"`%s` INT UNSIGNED NOT NULL".format(key)
			),
			tableKeys.map!(key =>
				"`%s`".format(key)
			),
			tableName,
			tableKeys.map!(key =>
				"`%s`".format(key)
			),
			tableKeys.map!(key =>
				"FOREIGN KEY(`%s`)
					REFERENCES `strings`(`id`)
					ON DELETE CASCADE"
				.format(key)
			)
		));
	}

	void destroy()
	{
		cn.exec("
			DROP TABLE IF EXISTS `%s`;
		".format(
			tableName
		));
	}

	@property
	bool empty()
	{
		return length < 1;
	}

	size_t get(Strings sequence, String token)
	{
		return cn.querySingle("
			SELECT `occurrences`
			FROM `%s`
			WHERE %-(%s AND %)
			AND `token_id`=%d
			LIMIT 1;
		".format(
			tableName,
			tableKeys.join(sequence),
			token.toHash
		))[0]
		.coerce!size_t;
	}

	@property
	size_t length()
	{
		return cn.querySingle("
			SELECT COUNT(DISTINCT(%-(%s, %)))
			FROM `%s`;
		".format(
			tableKeys.map!(key =>
				"`%s`".format(key)
			),
			tableName
		))[0]
		.coerce!size_t;
	}

	Frequency[] list(Strings sequence)
	{
		return cn.query("
			SELECT DISTINCT(`token_id`), `occurrences`
			FROM `%s`
			WHERE %-(%s AND %);
		".format(
			tableName,
			tableKeys.join(sequence)
		))
		.map!(row =>
			Frequency(
				String.find(row[0].coerce!size_t),
				row[1].coerce!size_t
			)
		)
		.array;
	}

	String random()
	{
		return cn.querySingle("
			SELECT `token_id`
			FROM `%s`
			ORDER BY RAND()
			LIMIT 1;
		".format(
			tableName
		))
		.transform!(row =>
			String.find(row[0].coerce!size_t)
		);
	}

	void set(Strings sequence, String token)
	{
		if(cn.exec("
			UPDATE `%s`
			SET `occurrences`=`occurrences` + 1
			WHERE %-(%s AND %) AND `token_id`=%d
			LIMIT 1;
		".format(
			tableName,
			tableKeys.join(sequence),
			token.toHash
		)) == 0)
		{
			cn.exec("
				INSERT INTO `%s`
				VALUES(%-(%d, %), %d, 1);
			".format(
				tableName,
				sequence[].map!toHash,
				token.toHash
			));
		}
	}
}

@property
private Connection cn()
{
	return ConnectionManager.get.connection;
}

private string getTableName(int Count)()
{
	return "counters_%d".format(Count);
}

private string[] getTableKeys(int Count)()
{
	return
		iota(0, Count)
		.map!(i => "key_%d_id".format(i + 1))
		.array;
}

private string[] join(int Count)(string[] keys, String[Count] sequence)
{
	return keys
		.zip(sequence[])
		.map!(key =>
			"`%s`=%d".format(
				key[0], key[1].toHash
			)
		)
		.array;
}
