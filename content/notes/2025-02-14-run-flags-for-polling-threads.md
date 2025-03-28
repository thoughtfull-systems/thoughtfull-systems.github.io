---
date: 2025-02-14T19:35:00-05:00
title: "Run flags for polling threads"
description: "How do you gracefully stop a polling thread simply and instantly?"
aliases:
- 2025-02-14-run-flags-for-threads
---

When a thread must wait `Thread/sleep` is usually the wrong thing to reach for.  It is best for a
thread to park waiting for something specific to happen like reading a socket or acquiring a lock.

However, some threads poll external systems in a poll/sleep loop and there's not much you can do
about it.

When you have a poll/sleep loop, how do you gracefully stop a polling thread simply and instantly?

## Thread/.interrupt

The first option you should consider is `Thread/.interrupt`.[^1] This is built-in to the JVM and the
preferred way to stop a thread (as opposed to `Thread/.stop` which is broken and deprecated).

```clojure {linenos=table}
(let [f (future
          (while (not (Thread/interrupted))
            (try
              (do-some-work)
              (Thread/sleep 1000)
            (catch InterruptedException _))))]
  ,,,
  (future-cancel f))
```

{{<alert "circle-info">}}
In this case I'm using `future-cancel` which does two things: it tries to stop the future from ever
starting, or if it has already started then it will interrupt it.  I'm going to just refer to this
as `Thread/.interrupt`.
{{</alert>}}

There may be other reasons, but the main undesirability for me is the forcefulness.  If the thread
is in some specific situations (like `Object/.wait` or `Thread/sleep`), then interrupting it will
throw an `InterruptedException`.  This could happen on line 5, or it could happen anywhere in the
dynamic extent of the thread (like `do-some-work`).

I'd like a method for graceful shutdown that allows `do-some-work` to complete before stopping the
thread, rather than forcing it to throw an `InterruptedException`.  Interruption should be a last
resort to force an unresponsive thread to stop, not for ordinary, graceful shutdown.  I would ask it
nicely to stop first, and if it does not stop after an elapsed timeout, then as a backstop I would
force it with `Thread/.interrupt`.

## An atom

I have often used an atom containing a boolean as a flag to control a polling thread.  For example:

```clojure {linenos=table}
(let [running? (atom true)]
  (future
    (while @running?
      (do-some-work)
      (Thread/sleep 1000)))
  ,,,
  (reset! running? false))
```

This works, but the problem is the thread could be sleeping when I reset the atom, in which case it will wait for a full sleep interval before stopping.  If the sleep interval is long, then the latency for shutting down the thread can be annoying.  In tests this becomes unbearable.  You might start and stop a service thread hundreds of times in tests and if you have to wait one second each time, it adds up!

## An atom + napping loop

You could use some kind of inner loop, only nap for 100 milliseconds at a time and check the atom,
then after enough 100 millisecond intervals add up, go back to the top of the loop.

```clojure {linenos=table}
(let [running? (atom true)]
  (future
    (while @running?
      (do-some-work)
      (let [end (+ (System/currentTimeMillis) 1000)]
        (while (and @running? (< (System/currentTimeMillis) end))
          (Thread/sleep 100)))))
  ,,,
  (reset! running? false))
```

This is better, but a bit more complicated (some auxiliary functions could help).  However, the
problem still exists, I've just reduced it to a 100 millisecond interval.  In production I may not
want to spin wait too tightly, but in test I want to spin as tightly and stop as quickly as
possible, and it still piles up across a bunch of tests.

Ideally we'd be able to instantly stop a thread.  I want a way to sleep interruptibly, but without
`Thread/sleep` and `Thread/.interrupt`.

## A channel

It is possible to use core.async to sleep interruptibly.[^2]

```clojure {linenos=table}
(let [stop (async/chan)]
  (future
    (while (not= stop (second (async/alts!! [(async/timeout 1000) stop])))
      (do-some-work)))
  ,,,
  (async/close! stop))
```

The thread will do work with a one second pause between tasks, but when I close `stop` it will exit
the loop.  This does exactly what I want.  I can gracefully stop a polling thread simply and
instantly.

## A promise

An even simpler way to accomplish this is to use a promise.

```clojure {linenos=table}
(let [running? (promise)]
  (future
    (while (deref running? 1000 true)
      (do-some-work)))
  ,,,
  (deliver running? false))
```

Until I deliver on the promise, the loop will sleep for one second before each iteration.  When I
deliver the promise, the deref will return instantly and the loop will exit.  This is a nearly identical solution to the core.async version.  In both cases we're waiting with a timeout for something to happen, if it times out, we go do something else then wait again.

This is version strictly simpler (but just barely) than the core.async version since there are fewer
dependencies and entities involved.

## An executor

Another option you have is to not even have a loop, but to use a `ScheduledExecutorService`.

```clojure {linenos=table}
(let [service (doto (Executors/newScheduledThreadPool 1)
                (.scheduleAtFixedRate #(do-some-work) 0 1 TimeUnit/SECONDS))]
  ,,,
  (.shutdown service))
```

This is a simple and elegant solution.  However, this is not all upside.  A big drawback is the
thread can only be asked to stop.  It has no control over exiting the loop early.

## Conclusion

`Thread/.interrupt` is too forceful, an atom introduces latency when stopping a thread, breaking a longer sleep into short naps is more complicated.

There are three options that accomplish my goal of gracefully stopping a polling thread simply and instantly: using core.async chans with alts!!, deref with a timeout on a promise, or using an executor.

There are trade-offs to each, however, I think the simplest, most applicable option is to simply
deref with a timeout on a promise.

[^1]: Thanks to jpmonettas for bringing this up on [Clojurians slack](http://clojurians.net/) and the ensuing discussion!
[^2]: Thanks to pwab for bringing this up on the [Reddit discussion](https://www.reddit.com/r/Clojure/comments/1jl3mrl/comment/mk1atpu/)!  I should have thought of this before, but I have a bias against core.async.

Discuss: {{<discuss-icon slack "https://clojurians.slack.com/archives/C8NUSGWG6/p1742811936759759">}} {{<discuss-icon fediverse "https://social.thoughtfull.systems/@technosophist/statuses/01JM3M460RBAQ1T5PPKDD8RR4K">}} {{<discuss-icon x-twitter "https://x.com/technosophist/status/1890576479328538982">}} {{<discuss-icon bluesky "https://bsky.app/profile/technosophist.thoughtfull.systems/post/3li6lha42cs2q">}} {{<discuss-icon reddit "https://www.reddit.com/r/Clojure/comments/1jl3mrl/run_flags_for_polling_threads/">}}
