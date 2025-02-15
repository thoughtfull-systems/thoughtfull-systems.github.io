---
title: "Run flags for threads"
date: 2025-02-14T19:35:00-05:00
---

How do you stop a background thread simply and instantly?

## An atom

I have often used an atom containing a boolean as a flag to control a background worker thread.  For example:

```clojure {linenos=table}
(let [running? (atom true)]
  (future
    (loop []
      (when @running?
        (do-some-work)
        (Thread/sleep 1000)
        (recur))))

  ,,,

  (reset! running? false))
```

This works, but the problem is the thread could be sleeping when I reset the atom, in which case it will wait for a full sleep interval before stopping.  If the sleep interval is long, then the latency for shutting down the thread can be annoying.  In tests this becomes unbearable.  You might start and stop a service thread hundreds of times in tests and if you have to wait one second each time, it adds up!

## An inner loop

My first thought was to try some kind of inner loop, only sleep for 100 milliseconds at a time and check the atom, then after enough 100 millisecond intervals add up, go back to the top of the loop.

```clojure
(let [running? (atom true)]
  (future
    (loop []
      (when @running?
        (do-some-work)
        (let [end (+ (System/currentTimeMillis) 1000)]
          (loop []
            (when (and @running? (< (System/currentTimeMillis) end))
              (Thread/sleep 100)
              (recur))))
        (recur))))

  ,,,

  (reset! running? false))
```

This is better, but a bit more complicated (some auxiliary functions could help).  However, the problem still exists, I've just reduced it to a 100 millisecond interval.  In production I may not want to spin wait too tightly, but in test I want to spin as tightly and stop as quickly as possible, and it still piles up across a bunch of tests.

Ideally we'd be able to instantly stop a thread.  I want a way to sleep interruptibly.

## A promise

I finally realized a simple way to accomplish this is to use a promise.  I can deref the promise with a timeout.

```clojure
(let [running? (promise)]
  (future
    (loop []
      (when (deref running? 1000 true)
        (do-some-work)
        (recur))))

  ,,,

  (deliver running? false))
```

The deref will return instantly and the loop exit when I deliver false.  This is much simpler than an inner loop.

An atom introduces latency when stopping a thread, breaking a longer sleep into short naps is more complicated, but deref with a timeout on a promise does the trick!
