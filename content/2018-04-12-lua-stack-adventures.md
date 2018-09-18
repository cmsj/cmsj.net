title: Adventures in Lua stack overflows
slug: lua-stack-adventures.md
date: 2018-04-13


[Hammerspoon](http://www.hammerspoon.org) is heavily dependent on [Lua](http://www.lua.org) - it's the true core of the application, so it's unavoidable that we have to interact with Lua's C API in a lot of places. If you've never used it before, Lua's C API is designed to be very simple to integrate with other code, but it also places a fairly high burden on developers to integrate it properly.

One of the ways that Lua remains simple is by being stack based - when you give Lua a C function and make it available to call from Lua code, you have to conform to a particular way of working. The function arguments supplied by the user will be presented to you on a stack, and when your C code has finished its work, the return values must have been pushed onto the stack. Here's an example:

```C
static int someUsefulFunction(lua_State *L) {
    // Fetch our first argument from the stack
    int someNumber = lua_tointeger(L, 1);

    // Fetch our second argument from the stack
    char *someString = lua_tostring(L, 2);

    /* Do some useful work here */

    // Push two return values onto the stack and return 2 so Lua knows how many return values we provided
    lua_pushstring(L, "some result text");
    lua_pushinteger(L, 42);
    return 2;
}
```

All simple enough.

In this scenario of calling from Lua→C, Lua creates a pseudo-stack for you, so while it's good practice to keep the stack neat and tidy (i.e. remove things from it that you don't need), it's not critical because apart from the return values, the rest of the stack is thrown away. That pseudo-stack only has 20 slots by default though, so if you're pushing a lot of return arguments, or using the stack for other things, you may need to use `lua_checkstack()` to grow it larger, up to the maximum (2048 slots).

Where things get more interesting, is when you're interacting with the Lua stack without having crossed a Lua→C boundary. For example, maybe you're in a callback function that's been triggered by some event in your C program, and now you need to call a Lua function that the user gave you earlier. This might look something like this:

```C
int globalLuaFunction;
void someCallback(int aValue, char* aString) {
    // Fetch a pointer to the shared Lua state object
    lua_State *L = some_shared_lua_state_provider();

    // Push onto the stack, the Lua function previously supplied by the user, from Lua's global registry
    lua_rawgeti(L, LUA_REGISTRYINDEX, globalLuaFunction);

    // Push the two arguments for the Lua function
    lua_pushinteger(L, aValue);
    lua_pushstring(L, aString);

    // Call the Lua function, telling Lua to expect two arguments
    lua_call(L, 2, 0);

    return;
}
```

Slightly more complex than the last example, but still manageable. Unfortunately in practice this is a fairly suboptimal implementation of a C→Lua call - storing things in the `LUA_REGISTRYINDEX` table is fine, but it's often nicer to use multiple tables for different things. The big problem here though is that `lua_call()` doesn't trap errors. If the Lua code raises an exception, Lua will `longjmp` to a panic handler and `abort()` your app.

So, writing this a bit more completely, we get:

```C
int luaCallbackTable;
int globalLuaFunctionRef;
void someCallback(int aValue, char* aString) {
    // Fetch a pointer to the shared Lua state object
    lua_State *L = some_shared_lua_state_provider();

    // Push onto the stack, the table we keep callback references in, from Lua's global registry
    lua_rawgeti(L, LUA_REGISTRYINDEX, luaCallbackTable);

    // Push onto the stack, from our callback reference table, the Lua function previously supplied by the user
    lua_rawgeti(L, -1, globalLuaFunctionRef);

    // Push the two arguments for the Lua function
    lua_pushinteger(L, aValue);
    lua_pushstring(L, aString);

    // Protected call to the Lua function, telling Lua to expect two arguments
    lua_pcall(L, 2, 0, 0);

    return;
}
```

Ok so this is looking better, we have our own table for neatly storing function references and we'll no longer `abort()` if the Lua function throws an error.

However, we now have a problem, we're leaking at least one item onto Lua's stack and possibly two. Unlike in the Lua→C case, we are not operating within the safe confines of a pseudo-stack, so anything we leak here will stay permanently on the stack, and at some point that's likely to cause the stack to overflow.

Now here is the kicker - stack overflows are really hard to find by default, you don't typically get a nice error, your program will simply leak stack slots until the stack overflows, far from the place where the leak is happening, then segfault, and your backtraces will have very normal looking Lua API calls in them.

If we were to handle the stack properly, the above could would actually look like this (and note that we've gone from four Lua API calls in the first C→Lua example, to eight here):

```C
int luaCallbackTable;
int globalLuaFunctionRef;
void someCallback(int aValue, char* aString) {
    // Fetch a pointer to the shared Lua state object
    lua_State *L = some_shared_lua_state_provider();

    // Find luaCallbackTable in the Lua registry, and push it onto the stack
    lua_rawgeti(L, LUA_REGISTRYINDEX, luaCallbackTable);

    // Find globalLuaFunctionRef in luaCallbackTable, and push it onto the stack
    lua_rawgeti(L, -1, globalLuaFunctionRef);

    // Remove luaCallbackTable from the stack *THIS WAS LEAKED IN THE ABOVE EXAMPLE*
    lua_remove(L, -2);

    // Push the two arguments for the Lua function
    lua_pushinteger(L, aValue);
    lua_pushstring(L, aString);

    if (lua_pcall(L, 2, 0, 0) == false) {
        // Fetch the Lua error message from the stack
        char *someError = lua_tostring(L, -1);
        printf("ERROR: %s\n", someError);

        // Remove the Lua error message from the stack *THIS WAS LEAKED IN THE ABOVE EXAMPLE*
        lua_pop(L, -1);
    }

    return;
}
```

Hammerspoon has been having problems like this for the last few months - lots of crash reports that on the surface, look like completely valid code was executing. I have to admit that it took me a lot longer than it should have, to realise that these were Lua stack overflows rather than my initial suspicion (C heap corruption), but we figured it out eventually and have hopefully fixed all of the leaks.

So, how did we discover that the problem was stack overflows, and how did we discover where all of the leaks were without manually auditing all of the places where we make C→Lua transitions (of which there are over 100). The answer to the first question is very simple, by defining `LUA_USE_APICHECK` when compiling Lua, it will do a little extra work to verify its consistency. Crucially, this includes calling `abort()` with a helpful message when the stack overflows. We turned this on for developers in March and then released 0.9.61 with it enabled, in early April. It's not normally recommended to have the API checker enabled in production because it calls `abort()`, but we felt that it was important to get more information about the crashes we couldn't reproduce.

Within a few days we started getting crash reports with the words `stack overflow` in them (as well as a few other errors, which we were able to fix), but that is only half the battle.

Having discovered that we did definitely have a stack leak somewhere, how did we discover where it was? This did involve a little brute force effort, but thankfully not a full manual audit of all 107 C→Lua call sites. Instead, I wrote two macros:

```C
#define _lua_stackguard_entry(L) int __lua_stackguard_entry=lua_gettop(L);
#define _lua_stackguard_exit(L) assert(__lua_stackguard_entry == lua_gettop(L));
```

These are very simple to use - you call `_lua_stackguard_entry()` just after you've obtained a pointer to the Lua state object, and then you call `_lua_stackguard_exit()` at every point where the function can return after that. It records the size of the stack (`lua_gettop()`) at the entry point and `assert()`s that it's the same at the exit point (`assert()` also calls `abort()` if something is wrong, so now we would get crash logs with the crash in the actual function where the leak is happening).
These entry/exit calls were then added to all 107 call sites 4 days after the 0.9.61 was released and I spent 3 evenings testing or manually verifying every site, before releasing 0.9.65 (0.9.62-0.9.64 fixed some of the other bugs found by the API checker in the mean time).

At the time of writing we're only 24 hours past the release of 0.9.65, but so far things are looking good - no strange Lua segfault crash reports as yet. There was one issue found today where I'd placed a `_lua_stackguard_exit()` call after a C statement that seemed unimportant, but actually caused an important object to be freed, but that is [already fixed](https://github.com/Hammerspoon/hammerspoon/commit/95a13554c65568aca2ee6db040895c6345b01b50) and will be included in 0.9.66.

Assuming we have now fixed the problem, after months of head-scratching, and a few weeks of research, testing and coding, it turns out that across the 107 call sites we only had two stack leaks - [one was in the code that handles tab completion in Hammerspoon's Console window](https://github.com/Hammerspoon/hammerspoon/commit/2b7abf2b33e3ddb17d87e548725959a8bba1ac40#diff-d0e4e7c56ae114494056acc9758d118fR797), and [the other was in `hs.notify`](https://github.com/Hammerspoon/hammerspoon/commit/f199351538d7b81bd4a01f349ddeb2e33e76d8e7). Hopefully you're all enjoying a more stable Hammerspoon experience, but I think we'll be leaving both the API checker and the stack guard macros enabled since they make it very easy to find/fix these sorts of bugs. I'd rather get a smaller number of crashes sooner, than have more months of head-scratching!

Discuss on [Twitter](https://twitter.com/cmsj/status/984592229472833536) | Discuss on [Hacker News](https://news.ycombinator.com/item?id=16826199)