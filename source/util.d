
module util;

auto removeAll(V, K)(V[K] assoc)
{
	foreach(key, value; assoc)
	{
		assoc.remove(key);
	}
}
