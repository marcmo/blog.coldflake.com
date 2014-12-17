---
layout:     post
title: Testing C++ With A New Catch
subtitle: Most test-frameworks are kind of lame - this one is not
author:     "Oliver Mueller"
tags: [C++, testing]
tag_weights: [15,25]
header-img: "img/catch.jpg"
credits_name: clappstar
credits_url: https://www.flickr.com/photos/clappstar/
credits_license: https://creativecommons.org/licenses/by-nc-nd/2.0/
---

Unit Testing frameworks are mostly boring -- if they are any good, they follow the rough approach of
the x-unit family that Kent Beck introduced with smalltalk. And in languages like ruby or even
Java they are quite comfortable and can make use of the runtime introspection capabilities, mostly
to automatically discover your test cases and execute them. Not so in C++. And the test frameworks
here always feel a little clumsy. CppUnit has an arcane way of writing and registering your
testcases. I was a user once, never again. As so often [boost] has a superior solution ([Boost.Test])
but it's reeeeeeeally a pain to set it up -- so I ended up not using it either.  
A noteworthy exception to the depressing C++ testing landscape is [gtest], googles own testing
framework for C++ that aims at portability and ease of use. It heavily relies on macros to provide
kind of a nice syntax and automatic test registration. It's light weight, extensible and works on
most platforms out-of-the-box. It has become my default turn-to solution for writing C++ unit tests.
Digging into it's features reveals that it is capable of rather non standard niceties like
repeatedly running the test cases while randomizing the execution order, running a subset of your
tests (using exclude/include patterns on invocation) or turning assertion errors directly into
debugger break-points.

## Enter the world of Catch

I just found out recently about [Catch] while watching someone explain a piece of code along with it's
tests. The first thing that kind of sticks out is that the tests seem to have a very clear visual
outline. That might seem silly but when looking at a piece of code I really like it when I can
get a feeling for the program structure merely by the outline of the text of the program. And that is
caused by one of the most intriguing aspects of [Catch]: rather then to use the classical `setup` --
`test` -- `teardown` cycle, the test-cases are organized into nested sections. The inner-most
sections (the *leaf*-sections) are the actual units under test, and they are executed along with
their enclosing sections. That immediately allows to reuse setup and tear-down code -- on multiple
levels.  
What I found is that my test cases got considerable shorter since a lot of times there is some
common setup steps or even test steps that are actually duplicated in a couple of test cases. The
classic *one-setup-approach* is just not enough here. The image shows the outline of the tests
[before] and [after] porting them from gtest to [Catch].

<img class="img-responsive" src="{{ site.baseurl }}/img/catch/code_outline.png" alt="">

## Quick Setup

One thing C++ programmers (or at least me) envy in the javascript/[nodejs] community is the uniform
and quick way to start a project and add the dependencies. It's quite common to check out a project
from github, do a quick `npm install` and have all dependencies installed in the local project
directory within seconds.  
*Catch* is a header-only library (thanks!!) and getting up to speed is just as fast: `wget` the
latest [all-in-one-header] file, add 2 lines to your test file, and everything is ready!

{% highlight cpp %}
#include "Bitstream.h"
#define CATCH_CONFIG_MAIN
#include "catch.hpp"

TEST_CASE("getOneBit")
{
    uint8_t data[1];
    BitstreamReader bs(data, 1);
    data[0] = 1 << 7;
    REQUIRE(0b1 == bs.get<1>());
}
{% endhighlight %}

No need to derive from a Test-Base class or anything like that. Pretty much just include the header,
request a predefined `main` function, and write your test-case.

## Behavior Driven anyone?

Quite amazingly the *section*-based design lets you use a [BDD]-flavored syntax without having to
add any implementation. Here is an example of how it can be used:

{% highlight cpp %}
SCENARIO("BitstreamTest: read bits from stream", "[getters]")
{
    GIVEN("A Bitstream with 1 byte of data")
    {
        uint8_t data[1];
        BitstreamReader* bs = new BitstreamReader(data, 1);
        WHEN("we set the leftmost bit")
        {
            data[0] = 1 << 7;
            THEN("we should get 1 when reading 1 bit")
            {
                REQUIRE(0b1 == bs->get<1>());
            }
        }
    }
}
{% endhighlight %}

Will produce an output something like that:

{% terminal tmp %} >
Scenario: BitstreamTest: read bits from stream
     Given: A Bitstream with 1 byte of data
      When: we set the leftmost bit
      Then: we should get 1 when reading 1 bit
    ...
{% endterminal %}

`SCENARIO` is merely a synonym for `TEST_CASE`, `GIVEN` and `WHEN` are synonyms for `SECTION`. So
simple but results in a beautiful DSL.

## Simplicity all the way

In contrast to other Unit-testing frameworks, [Catch] does not offer the usual selection of assert
macros but manages to get away with basically just 2 kinds: `REQUIRE` and `CHECK`.  `REQUIRE`
evaluates a boolean expression and stops the tests as soon as there is an assertion failure. `CHECK`
does the same thing but keeps the tests going, reporting what went wrong in the end. And the reports
you get are even really specific, not just something like the _"...expected True but was False..."_
kind of junk.

{% terminal tmp %} >
...
test/BitstreamTest.cpp:31: FAILED:
  REQUIRE( 0b1 == bs->get<2>() )
with expansion:
  1 == 3
...
{% endterminal %}

## Command line Tool

With the executable you get a decent command line parser built in that gives you a lot of
options. Rather then to just execute every test-case, you can select the cases to be executed using
a simple glob-like pattern (e.g. `put*` matches tests starting with `put`, `~put*` everything else).  
Another option I really like is the `--list` option, which tells you about all available tests.
Almost a little bit like `rake -T` is used to display the available tasks in a rakefile.  `--tags`
is similar but shows the available tags instead (test-cases can be tagged with multiple strings
which makes it very convenient to restrict the executed test-cases, e.g. to just run the tests that
deal with insertion etc.).  
By default [Catch] is very quiet and does not report on successful test-cases. Sometimes it's
nice to see them as well so you can use the `-s` or `--success` option to do so.  
There are a lot more options to explore, here are the ones of the current version:

{% terminal tmp %} > test_executable -h
Catch v1.0 build 53
usage:
  bitstream.exe [<test name, pattern or tags> ...] [options]

where options are:
  -?, -h, --help               display usage information
  -l, --list-tests             list all/matching test cases
  -t, --list-tags              list all/matching tags
  -s, --success                include successful tests in output
  -b, --break                  break into debugger on failure
  -e, --nothrow                skip exception tests
  -i, --invisibles             show invisibles (tabs, newlines)
  -o, --out <filename>         output filename
  -r, --reporter <name>        reporter to use (defaults to console)
  -n, --name <name>            suite name
  -a, --abort                  abort at first failure
  -x, --abortx <no. failures>  abort after x failures
  -w, --warn <warning name>    enable warnings
  -d, --durations <yes/no>     show test durations
  -f, --input-file <filename>  load test names to run from a file
  --list-test-names-only       list all/matching test cases names only
  --list-reporters             list all reporters
{% endterminal %}

## Give it a Try!

Catch might not be the test-framework with the most features but it certainly brings a fresh new
approach to the table. It's trivial to setup and use and that alone should be a reason to use it.
From the limited time I spent playing with it I already found it has given me some nice benefits. I
plan to use it even more in the future.

---

_Edit:_ Someone made me aware of [UnitTest++]. I had a brief look at it but immediately bailed when
I saw the comment in the docs:

> "Pre-requisites: While there are currently some bundled makefiles and
> projects, UnitTest++ is primarily built and supported using CMake."


[Catch]:https://github.com/philsquared/Catch
[Boost.Test]:(http://www.boost.org/doc/libs/1_49_0/libs/test/doc/html/index.html)
[gtest]:{% post_url 2011-07-11-gtest %}
[boost]:http://www.boost.org/
[before]:https://github.com/marcmo/bitstream/blob/46ae519fe3abbfaa8157464fc57a26b8eeae57b2/test/BitstreamTest.cpp
[after]:https://github.com/marcmo/bitstream/blob/b39b301ed15c05a3af81ecc8837ab12c46eead7e/test/BitstreamTest.cpp
[nodejs]:http://nodejs.org/
[npm]:https://www.npmjs.org/
[all-in-one-header]:https://raw.githubusercontent.com/philsquared/Catch/master/single_include/catch.hpp
[BDD]:http://en.wikipedia.org/wiki/Behavior-driven_development
[UnitTest++]:https://github.com/unittest-cpp/unittest-cpp
