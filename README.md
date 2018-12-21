# gerbil-names-index
Tool for generating exported Gerbil names

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
```
