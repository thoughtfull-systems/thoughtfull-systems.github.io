---
title: "Enafore hacks"
date: 2024-12-10T16:40:00-05:00
---
As a relative noob to the fediverse, I was surprised to find that [GotoSocial](https://gotosocial.org/) (which I decided to use as my ActivityPub server) does not have a "UI."  It makes sense I guess, why not also federate the user experience?

I have [Tusky](https://tusky.app/) on my Android, which is pretty nice, and looking around for a web client, I found [Semaphore](https://github.com/NickColley/semaphore) (R.I.P.) which is an archived fork of [Pinafore](https://github.com/nolanlawson/pinafore) (also R.I.P.).  The life and death of two clients flashed before my eyes within hours.

However, there is *another* fork of Pinafore called [Enafore](https://github.com/enafore/enafore).[^1]  It seems to have some legs, but also some things that I don't like about it, so I changed them.  I'm not really a TypeScript developer, but I didn't let that stop me.

## ~Toots~Posts

I don't know if it's juvenile to use the word "toot" or if I'm juvenile for not wanting to use the word "toot."  Maybe we're all adults here?  I'm using my adulting agency to not use the word "toot."  It turns out that someone else had a [similar idea](https://github.com/enafore/enafore/commit/6989ac224bd61b343c4b05cd39dd7f18e305b54a)(?), so I didn't actually have to [do much](https://github.com/thoughtfull-systems/enafore/commit/1d2037cc3bd3bf34be33beeee80a7eb14436eadc).

## Bookmarks

I have found that a healthier way to use social media is to just skim through all the ... posts ... of my follows and bookmark things I want to come back to.  This usually includes posts with links.  It is easy to burn a bunch of time going down rabbit holes reading things.  I like to bookmark, then come back later to a cache of interesting articles to read.

That said, I kind of need to be able to bookmark and unbookmark quickly and hiding that in a submenu didn't work for me.  So I [added](https://github.com/thoughtfull-systems/enafore/commit/c4f5ac6837822573cc511cbb0ef3e5fe7da8d669) it to the status toolbar at the bottom of a status.

![The enafore toolbar from a status post that has a bookmark icon as an additional action](/2024-12-10/status-toolbar.png "Enafore toolbar with a fancy bookmark icon")

## Single instance

Finally, I [modified](https://github.com/thoughtfull-systems/enafore/commit/703fa05cd0c888fcfcbe16df54787b4977cbc6eb) the Github actions to build as a single instance UI.  I don't really want to host something for other people to use (even on Github pages).  Since it is a SPA front end to GotoSocial, it builds and hosts on Github pages and I just point a [DNS record](https://enafore.thoughtfull.systems) at it.

## Conclusion

I wanted
- "Posts" not "toots"
- Easy bookmorking
- Something just for me

...and that's what I did!

My lawyer (if I had one) said I have to publish this code, since it's AGPL'ed and all, so here it is [https://github.com/thoughtfull-systems/enafore](https://github.com/thoughtfull-systems/enafore).

One thing I'm still figuring out is where is the line between client and server.  I've configured Enafore to not show replies in my timeline, but Tusky still does because I guess that's a client configuration?  I've also turned off boosts for some of my follows, and this (surprise!) works across clients.  That's kind of annoying, but I guess it's the cost of sovereignty.


Discuss on:
- [ X](https://x.com/technosophist/status/1866613342032249212)
- [Bluesky](https://bsky.app/profile/technosophist.thoughtfull.systems/post/3lcycleeaik2r)
- [ActivityPub](https://social.thoughtfull.systems/@technosophist/statuses/01JESBJASSVGHHXMHAJNCZJT3T)


[^1]: I was pretty confused for a while and kept using the wrong one, but I think I've got it straight now.

