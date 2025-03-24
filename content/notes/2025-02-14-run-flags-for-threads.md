---
title: "Run flags for threads"
date: 2025-02-14T19:35:00-05:00
---

How do you gracefully stop a background thread simply and instantly?

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

There may be other reasons, but the main undesirability is the forcefulness.  If the thread is in
I/O or `Object/.wait` or `Thread/sleep` (or other situations), then interrupting it will throw an
`InterruptedException`.  I'd like a method for graceful shutdown that allows `do-some-work` to
complete before stopping the thread, rather than forcing it to throw an `InterruptedException` in
the middle of `do-some-work` and its call tree.

Interruption should be a last resort to force an unresponsive thread to stop, not for ordinary,
graceful shutdown.  I would ask it nicely to stop first, and if it does not stop after an elapsed
timeout, then as a backstop I would force it with `Thread/.interrupt`.

## An atom

I have often used an atom containing a boolean as a flag to control a background worker thread.  For example:

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

## An inner loop

My first thought was to try some kind of inner loop, only sleep for 100 milliseconds at a time and check the atom, then after enough 100 millisecond intervals add up, go back to the top of the loop.

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

This is better, but a bit more complicated (some auxiliary functions could help).  However, the problem still exists, I've just reduced it to a 100 millisecond interval.  In production I may not want to spin wait too tightly, but in test I want to spin as tightly and stop as quickly as possible, and it still piles up across a bunch of tests.

Ideally we'd be able to instantly stop a thread.  I want a way to sleep interruptibly.

## A promise

I finally realized a simple way to accomplish this is to use a promise.  I can deref the promise with a timeout.

```clojure {linenos=table}
(let [running? (promise)]
  (future
    (while (deref running? 1000 true)
      (do-some-work)))
  ,,,
  (deliver running? false))
```

The deref will return instantly and the loop exit when I deliver false.  This is much simpler than an inner loop.

`Thread/.interrupt` is too forceful, an atom introduces latency when stopping a thread, breaking a longer sleep into short naps is more complicated, but deref with a timeout on a promise does the trick!

[^1]: Thanks to jpmonettas for bringing this up on [Clojurians slack](http://clojurians.net/) and the ensuing discussion!

Discuss on:
- [ X](https://x.com/technosophist/status/1890576479328538982)
- [Bluesky](https://bsky.app/profile/technosophist.thoughtfull.systems/post/3li6lha42cs2q)
- [ActivityPub](https://social.thoughtfull.systems/@technosophist/statuses/01JM3M460RBAQ1T5PPKDD8RR4K)
- [Slack](https://clojurians.slack.com/archives/C8NUSGWG6/p1742811936759759)
