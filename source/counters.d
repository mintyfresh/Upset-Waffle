
module counters;

version(UseMySQL)
{
	public import database.counters;
}
else
{
	public import memory.counters;
}
