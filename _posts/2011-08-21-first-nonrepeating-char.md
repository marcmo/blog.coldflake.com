---
layout:     post
title: Lunch break coding - First Nonrepeating Character
subtitle: Simple programming puzzle to find the first nonrepeating character in a string.
header-img: "img/domino.jpg"
tags: [haskell, puzzle, algorithm]
tag_weights: [30,25,20]
redirect_from:
  - /posts/2011-08-21-first-nonrepeating-char.html
credits_name: Mikey Phillips
credits_url: https://www.flickr.com/photos/mikeyphillips/
credits_license: https://creativecommons.org/licenses/by-nc-nd/2.0/
---

Again a little programming task frome [here](http://programmingpraxis.com/2011/08/19/first-non-repeating-character/):

> Write a function that takes an input string and returns the first character from the string that is not repeated later in the string. For instance, the two letters “d” and “f” in the input string “aabcbcdeef” are non-repeating, and the function should return “d” since “f” appears later in the string. The function should return some indication if there are no non-repeating characters in the string. 

Seems like `Data.List` should have everything we need for a simple solution.

{% highlight haskell %}
import Data.List(group,find,sort)
{% endhighlight %}

We are given a string of character and first filter out the characters that are unique.  
Once those are assembled, we can recursively walk over the characters in the input string and find the first character that is unique:

{% highlight haskell %}
firstNonRepeating ::  Ord a => [a] -> Maybe a
firstNonRepeating xs = walkTill uniques xs where
  uniques = [head ys | ys <- group $ sort xs
                     , ((==) 1 . length) ys ]
  walkTill _ [] = Nothing
  walkTill uniques (x:xs)
    | x `elem` uniques = Just x
    | otherwise = walkTill uniques xs
{% endhighlight %}

A quick test to verify the algorithm:

<pre class="terminal">
*Main> firstNonRepeating "aabcbcdeef"
Just 'd'
*Main> firstNonRepeating "a................b..................c...................d"
Just 'a'
*Main> firstNonRepeating "aa....bb.....cc.....dd"
Nothing
</pre>

Full source-code is available [here](/code/firstNonrepeating/algorithm.hs).
