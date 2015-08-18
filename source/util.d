
module util;

import std.typetuple;

auto removeAll(V, K)(V[K] assoc)
{
	foreach(key, value; assoc)
	{
		assoc.remove(key);
	}
}

template TemplateSequence(int Count, alias Value)
if(Count == 0)
{
	alias TemplateSequence = TypeTuple!();
}

template TemplateSequence(int Count, alias Value)
if(Count >= 1)
{
	alias TemplateSequence = TypeTuple!(
		Value, TemplateSequence!(Count - 1, Value)
	);
}
