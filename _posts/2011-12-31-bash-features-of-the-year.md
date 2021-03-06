---
layout:     post
title: Top 10 Unix Command Line Utilities 2011
subtitle: A selection of the most useful bash commands I (re)-discovered this year.
header-img: "img/wood_tools.jpg"
tags: [unix, bash]
tag_weights: [20,30]
redirect_from:
  - /posts/2011-12-31-bash-features-of-the-year.html
credits_name: Marco Ferracuti
credits_url: https://www.flickr.com/photos/mamaol/
credits_license: https://creativecommons.org/licenses/by-nc-nd/2.0/
---

<div class="table-of-contents">

{% markdown %}
### Content

* [diffing folders](#diffing-two-folders)
* [find a manpage](#manpages-for-a-specific-topic)
* [cut & paste](#cutpaste)
* [watch](#watch)
* [du](#du)
* [find](#find)
* [seq](#seq-command)
* [file & nm](#compiled-files)
* [host & dig](#dns-tools)
{% endmarkdown %}

</div>

Whenever I find some useful command line utility I made it a habit to write it down so that I can
come back later in case I don't remember. Turns out that it is quit a lot that I note.  
The following is a distilled version of my favorite ones from 2011 (in the meantime I did the same
thing for [2012] and [2013]). For most of them I found examples somewhere on the net but
unfortunately didn't not that information so I cannot refer back to the original source.

## 1> diffing two folders

The `diff` utility is usually used to compare two files line by line, but it can also be used in
other ways. Like this it's very useful to quickly find out difference between folders:

<pre class="terminal">
$ diff -rq folder1 folder2
</pre>

This will compare the 2 folders and look at each directory recursively (`-r`). The `-q` option puts
it into brief mode so that the result is more easy to browse.

## 2> manpages for a specific topic

Even though I use `man` all the time, I never knew that you can easily search all manpages with the
`-k` option. This is the result of searching in the manpages about "backup":

{% terminal blog.coldflake.git %}(master) > man -k backup
dump(8), rdump(8)        - filesystem backup
restore(8), rrestore(8)  - restore files or file systems ...
tdbbackup(8)             - tool for backing up and for ...
registry(3)              - Store and backup key-value pairs
{% endterminal %}

`man -k` is actually just another form of calling `apropos` which searches in a database of
descriptions of system commands for our search term. Results are displayed on the standard output.

## 3> cut/paste

I sometimes find it easier to use `cut` and `paste` instead of `awk` or `sed` for simple cases where
I needed to cut out selected portions of each line of a file or from the standard input and combine
them in a different way.

### count loc in a codebase

{% highlight bash %}
find -E . -regex ".*\.(cpp|c|h|hpp)" \
  | xargs -n1 wc -l \
  | cut -f1 -d'.' \
  | paste -sd+ - \
  | bc
{% endhighlight %}

In this example I use the BSD version of `find` on Mac OS to retrieve a list of all source code
files. Next `wc -l` is used to count the number of lines of each file. What we now have is a list of
numbers that we want to add together. This is where `cut` and `paste` can help: We first cut out
only the number (`-f1` takes the first item of the tokens that where split using the delimiter `-d`
'.'). Those number can then be combined using `paste` which reads from stdin (`-s`) and combines the
input tokens with + (`d+`).  
Finally everything is fed to `bc` that will do the calculation.

## 4> watch

A very useful utility that will run a command repeatedly. The output will be displayed. By default,
the program that it is told to execute will be run every 2 seconds. `watch` is kind of similar to
tail.

{% highlight bash %}
watch -n 60 ls -l # will execute ls -l every minute
{% endhighlight %}

Perhaps more interesting: Check your system cpu load repeatedly using `sar`:

{% highlight bash %}
watch -n 5 sar 1 1
{% endhighlight %}

This will collect and display system activities statistics every 5 seconds.

## 5> du

I despise most of the graphical file explorers and prefer never to have to leave the shell for
acquiring information about the system. A frequently occurring task for me is to display the size of
all files and folders in the current working directory. That is exactly what `du` was mad for...only
that the default output can be quite hard to read. So I found this solution that will print the
sizes of everything, sorted by size.

{% highlight bash %}
du -s ./* | sort -n | cut -f 2- | xargs -Ix du -sh x
{% endhighlight %}

This will first get the size of all items in the current directory and sort those according to their
block usage. Then it will drop the block size to only cut out the names (already sorted by size) and
rerun a `du` on those elements, this time using the "Human Readable" output. By the way, `du` is
smart enough to *not* do the calculation twice so this second round is pretty fast.  
Let's do a quick test run:

{% terminal blog.coldflake.git %}(master) > du -s ./* | sort -n | cut -f 2- \
  | xargs -Ix du -sh x
412K	./code
624K	./images
1.3M	./_site
1.9M	./_cache
3.5M	./deploy
106M	./bin
{% endterminal %}


## 7> find

`find` is a classic so I had to include it here.  
Ever tried to find files matching more than one pattern? There is a nice way you can tell `find` to do that: `-or`

{% highlight bash %}
find . -name "*.cpp" -or -name "*.h"
{% endhighlight %}

Here is another one: Want to mess with the timestamps and touch all files in directory recursively?

{% highlight bash %}
find . -exec touch {} \;
{% endhighlight %}

Or maybe find out which files that are found are actually executable?

{% highlight bash %}
for n in `find . -type f`;do if [ -x "$n" ];\
	then echo "executable:$n";fi; done
{% endhighlight %}

## 8> seq command

Was useful to me on some occasions:  `seq` for printing numbers. On Mac OS `seq` is not available
but `jot` can be used in a similar fashion.

{% highlight bash %}
seq 5       # prints numbers from 1 to 5
seq 5 10    # print numbers from 5 to 10
seq 0 2 10  # print even numbers from 0 to 10
seq 5 -1 1  # print numbers from 5 down to 1
{% endhighlight %}

I use it for example to generate files quickly:

{% terminal blog.coldflake.git %}(master) > touch $(seq -f "test%02g" 5)
<span class="prompt">blog.coldflake.git</span>(master) > ls
test01  test02  test03  test04  test05
{% endterminal %}

## 9> Compiled Files

The `file` utility can be used to identify the type of a file and is useful, among other cases, to
find out about the architecture for which a file was compiled.

{% terminal blog.coldflake.git %}(master) > file test.o
test.o: Mach-O 64-bit object x86_64
{% endterminal %}

`nm` is very useful to find out about the symbols listed in the symbol table of object-files and
libraries. It can be quite handy to search for the libraries that define a symbol:

{% terminal blog.coldflake.git %}(master) > nm -o /lib/* /usr/lib/* 2> /dev/null | grep 'printf$'
/usr/lib/dyld: 00007fff5fc1b3ef t ___simple_bprintf
/usr/lib/dyld: 00007fff5fc1bc54 t __simple_dprintf
/usr/lib/dyld: 00007fff5fc1bbe2 t __simple_vdprintf
/usr/lib/dyld: 00007fff5fc1bcf1 t __simple_vsprintf
/usr/lib/dyld: 00007fff5fc0a98b t _fprintf
...
{% endterminal %}


## 10> DNS tools

If you need some information regarding DNS those tools come in handy. `host` is a simple utility for performing DNS lookups. 

{% terminal blog.coldflake.git %}(master) > host coldflake.com
coldflake.com has address 173.230.139.188
coldflake.com mail is handled by 10 mail.coldflake.com.
{% endterminal %}

`dig` (domain information groper) can be used for interrogating DNS name servers. For example you
can use it to retrieve a list of DNS servers authoritative for a domain:

{% terminal blog.coldflake.git %}(master) > dig coldflake.com NS +noall +answer
; <<>> DiG 9.6-ESV-R4-P3 <<>> coldflake.com NS +noall +answer
;; global options: +cmd
coldflake.com.		83707	IN	NS	ns3.linode.com.
coldflake.com.		83707	IN	NS	ns4.linode.com.
coldflake.com.		83707	IN	NS	ns5.linode.com.
coldflake.com.		83707	IN	NS	ns1.linode.com.
coldflake.com.		83707	IN	NS	ns2.linode.com.
{% endterminal %}


[2011]:{% post_url 2011-12-31-bash-features-of-the-year %}
[2012]:{% post_url 2012-12-30-Top-10-Unix-Command-Line-Utilities-2012 %}
[2013]:{% post_url 2013-12-31-top-10-unix-command-line-utilities-2013 %}
