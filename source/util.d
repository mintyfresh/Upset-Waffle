
module util;

import std.typetuple;

auto removeAll(V, K)(V[K] assoc)
{
	foreach(key, value; assoc)
	{
		assoc.remove(key);
	}
}

auto transform(alias Pred, Param)(Param param)
{
	return Pred(param);
}
