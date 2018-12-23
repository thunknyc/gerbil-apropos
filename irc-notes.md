## Notes from IRC

```
12:08 E<edw> vyzo: Right now my biggest Gerbil itch is the absence of a comprehensive index of all names. Such a think could form the basis of something like the Clojure Grimoire, but even if it were a simple list of module-qualified names and an indication of whether something's a value/macro/proc, that would be a good start.
12:09 E<edw> vyzo: Such a thing should be generated from a single source of truth i.e. the source. If you could give me some pointers on how I could do that, I'd be willing to write a tool to do it.
12:32 V<vyzo> yeah, that would be awesome and indeed very interesting
12:32 V<vyzo> you can use the expander api
12:32 V<vyzo> look at import-module in gerbil/expander/module.ss
12:32 V<vyzo> you basically import the module you want
12:32 V<vyzo> and you can get the export set
12:33 V<vyzo> module-context-export gives you the export set
12:33 V<vyzo> and you can list those names for the module
12:33 V<vyzo> you can also look at the export binding
12:33 V<vyzo> to see whether it is a macro or a runtime symbol
12:34 V<vyzo> if you want to see it as a procedure, you can eval and possibly disassemble it
12:34 V<vyzo> for example code, look at src/misc/scripts/docsyms.ss
12:35 V<vyzo> edw: ^^^
12:35 V<vyzo> https://github.com/vyzo/gerbil/blob/master/src/misc/scripts/docsyms.ss
12:35 V<vyzo> given a module, it lists the exported names
12:36 V<vyzo> that could be a useful starting point
12:36 E<edw> vyzo: Thanks. Is there a way to get a list of all currently-available modules?
12:36 V<vyzo> imported or the ones sitting in the file system?
12:36 V<vyzo> you can get the library path
12:37 V<vyzo> and you can iterate the directories listed there
12:37 V<vyzo> try (expander-load-path)
12:37 V<vyzo> this gives you the list of paths that are the roots
12:38 V<vyzo> you can walk these directories looking for .ssi files
12:38 V<vyzo> which you can import
12:38 V<vyzo> and dump their symbols
12:41 V<vyzo> for already imported ones, try (gx#current-module-registry)
12:41 V<vyzo> errr (gx#current-expander-module-registry)
12:42 V<vyzo> this will give you a hash table of module id or path -> module object
12:42 V<vyzo> which you can get the export symbols in the same way
12:43 E<edw> vyzo: Thanks! I've recorded for posterity and my future reference: <https://github.com/thunknyc/gerbil-names-index/>.
12:52 E<edw> How would you like module-qualified names to be referred to? E.g. name `baz` in module `:foo/bar`.
12:56 E<edw> For now I'm going to emit a bunch of lists e.g. `((:foo/bar baz) ...)`.
12:57 V<vyzo> you can look at the binding itself
12:57 V<vyzo> and get the fully qualified name
12:58 V<vyzo> core-resolve-module-export
12:58 V<vyzo> will take an export
12:58 V<vyzo> and resolve it to its binding
12:59 V<vyzo> binding-id gives you the fully qualified name for the binding
13:02 V<vyzo> you might have to import the expander itself for some symbols
13:02 V<vyzo> try (import <expander-runtime>) first
13:02 V<vyzo> and if some symbls are not accessible, just import the expander itself
13:02 V<vyzo> (import :gerbil/expander)
13:02 V<vyzo> so if you take the binding id
13:02 V<vyzo> you can eval it
13:03 V<vyzo> and it will give you the runtime value
13:03 V<vyzo> which you can inspect to see what it is
13:05 E<edw> Cool. I'm sure this will all make more sense as I dig into it.
20:38 E<edw> vyzo: Is there a way I can eval X in the context of a module Y? so like, evaluate `'printf` in the context of `':std/format`, regardless of whether I have done an `(import :std/format)` at top level *if* that module has been loaded indirectly as part of another import?
22:31 E<edw> Also, what are the `e` elements accessible via `syntax-binding-e`, `alias-binding-e`, `import-binding-e`?
23:25 V<vyzo> yes, you can set the current-expander-context
23:25 V<vyzo> it's a paramemter
23:25 V<vyzo> you can set this to an arbitrary module context
23:25 V<vyzo> and eval in the context
23:26 V<vyzo> the -e elements depend on the binding
23:26 V<vyzo> so look at the implementation of enter!
23:26 V<vyzo> https://github.com/vyzo/gerbil/blob/master/src/gerbil/interactive/init.ss#L43
08:18 E<edw> vyzo: Perfect! Thanks.
11:17 E<edw> vyzo: If a module export is an import binding, how can I resolve it to its underlying module binding?
11:18 V<vyzo> core-resolve-export should still resolve it
11:18 V<vyzo> core-resolve-module-export
11:20 V<vyzo> you can also try resolve-identifier on the import-binding-e if that doesn't work
11:22 E<edw> Cool. I'll try those. I hope to have a toy version of Clojure-Grimoire-like thing by end of day.
11:24 O<ober> nice
11:24 V<vyzo> excellent
11:28 E<edw> What is the `e` element of this binding objects? What does `e` mean?
11:28 V<vyzo> e means element
11:29 V<vyzo> it's the expander value
11:29 V<vyzo> for syntax bindings it's the actual macro object
11:29 V<vyzo> for other objects it can be a syntax object or just a symbol
11:31 E<edw> Ah. So it's possible that the import-binding-e is another import-binding, and I should then recursively descend until I get a non-import-binding?
11:31 E<edw> …because that's what I'm seeing.
11:32 V<vyzo> yes
11:32 V<vyzo> look at resolve-identifier in gerbil/expander/core
11:32 V<vyzo> you should also be aware of alias-bindings
11:34 E<edw> I check for them but just flag them as aliases atm. Can they be resolved using c-r-m-e as well?
11:36 V<vyzo> they should resolve
11:36 V<vyzo> but again, i don't remember :)
11:36 V<vyzo> use resolve-identifier when in doubt
11:37 E<edw> Haha. Will do.
```
