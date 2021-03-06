# pushall.sh

POSIX-shell implementation of [pushall.ru API](https://pushall.ru/blog/api).

v. 0.1.4-alpha  
[![Build Status](https://travis-ci.org/nibb13/pushall.sh.svg?branch=master)](https://travis-ci.org/nibb13/pushall.sh)

## Features

* Self API
* Broadcast API
* Multicast API
* Unicast API
* Queueing

## Requirements

* POSIX shell (tested on busybox/ash)
* sed
* awk (awk / gawk / mawk)
* grep
* date
* curl

## Installation

Put pushall.sh and JSON.awk somewhere, then:

	chmod +x pushall.sh
	chmod +x JSON.awk

That's all.

Installation is user-dependent, your queue will not interfere with other user's queue.
Script uses `$XDG_DATA_HOME` defaulting to `~/.local/share`

## Usage

**Simple send using self API**  
*(Not recommended, use queue)*

`./pushall.sh -c self -t "Title" -T "Text" -u "http://yourdomain.com/messagetargeturl" -I "pushall_id" -K "pushall_key"`  
*(Will return LID or error message from API)*

**Add self API message to the end of the queue**

`./pushall.sh -c self -t "Title" -T "Text" -u "http://yourdomain.com/messagetargeturl" -I "pushall_id" -K "pushall_key" queue`  
*(Will return unique ID for message in queue)*

**Add self API message to the top of the queue**

`./pushall.sh -c self -t "Title" -T "Text" -u "http://yourdomain.com/messagetargeturl" -I "pushall_id" -K "pushall_key" queue top`  
*(Will return unique ID for message in queue)*

**Broadcast API messages**

Replace `-c self` by `-c broadcast` in above samples and use your channel ID / channel key instead of account ID / key.  
*(Will return LID or error message from API)*

**Multicast API messages**

Same as brodcast, but with `-c multicast`. Don't forget to set UIDs (-U) either in "[1,2,3]" or "1,2,3" format.  
*(Will return LID or error message from API)*

**Unicast API messages**

Same as multicast, but with `-c unicast`. UID (-U) is now single number.  
*(Will return number of devices which got your message or error message from API)*

**Run existing queue obeying API timeouts**

`./pushall.sh run`  
*(Will return LIDs or error messages from API)*

**Delete single message from queue**

`./pushall.sh delete <ID>`  
*(Use ID returned by `queue` or `queue top`)*

**Clear queue completely**

`./pushall.sh clear`

## Troubleshooting & caveats

* ~~All used locks are system-wide while queues aren't.~~ (Issue [#12](https://github.com/nibb13/pushall.sh/issues/12), closed in [2f68761](https://github.com/nibb13/pushall.sh/commit/2f68761b95c11cbda751d4bb4cdebad1e54059ad))
* If curl returns "exit code 60" with message *"curl: (60) SSL certificate problem, verify that the CA cert is OK."* then use `-b <ca bundle path>` for API calls & queue adding. You can get CA bundle [here](https://curl.haxx.se/docs/caextract.html).

## Benchmarks

*to be filled (if really needed)*

## Help wanted

Any mentions, suggestions, pull-requests, bug reports, usage reports etc. are welcome and appreciated. Really. I mean it.

## Thanks

[PushAll](https://pushall.ru) staff for nice service.  
[D-Link](http://dlink.com) for outstanding hardware.  
[step-](https://github.com/step-) for [JSON.awk](https://github.com/step-/JSON.awk).

## Contacts

<nibble@list.ru>  

Last update: 23.10.2017
