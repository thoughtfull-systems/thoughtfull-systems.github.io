---
title: "How to reuse a macro like a function"
date: 2025-05-30T14:45:33-04:00
---

If you want to reuse a macro, you can expand your macro into a use of another macro, but then you don't get a chance to change the generated code that results from the other macro.

```clojure
(defmacro my-macro [& body]
  `(another-macro ~@body)
  ;; but how do I do stuff with the output of another-macro‽
  )
```

Another way to reuse code in macros is by splitting it into helper functions:

```clojure
(defmacro with-awesome [& body]
  (let [body' (make-awesome body)]
    `(do ~@body')))
```

In this case, `make-awesome` will take code as data and return data and can be used in multiple macros.  That's fine.

But sometimes you want to *reuse* a macro, like add some functionality to an existing macro.  For example, suppose you want to riff on `defn`.  `defn` has some complicated syntax.  It can take an optional docstring.  It can take a param vector for a single arity then a body.  It can take multiple arities each with a param vector and body (and optional pre and post conditions!)

It would be a pain to either recreate all that functionality, or limit your macro so it only supports some of the functionality of the original.

What if you could reuse `defn` by just calling it like you call `make-awesome` above?

You can!

A macro is "just" a function called at compile-time with two secret arguments: `&form` and `&env`.  If you can trick the compiler into letting you call a macro like a function and you can supply `&form` and `&env`, then you don't have to recreate the macro's functionality, and you can collect its output for further macroing:

```clojure
(defmacro defn+ [& args]
  (let [[_def name [_fn & arities]] (apply @#'defn nil nil args)
        improved-arities (improve-the-arities arities)]
    `(def ~name (fn ~@improved-arities))))
```

If you want to do more than just expand to another macro or factor your macro into helper functions, you can reuse a macro by calling it like a function!

Discuss: {{<discuss-icon slack "https://clojurians.slack.com/archives/C8NUSGWG6/p1748632891959909">}} [{{<icon fediverse>}}](https://social.thoughtfull.systems/@technosophist/statuses/01JWHA8CQF2ASTY15B0HHF51FP) [{{<icon x-twitter>}}](https://x.com/technosophist/status/1928532456442855704) [{{<icon bluesky>}}](https://bsky.app/profile/technosophist.thoughtfull.systems/post/3lqfxcuki722l)
