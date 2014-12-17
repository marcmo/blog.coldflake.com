---
layout:     post
title: Lunch break coding
subtitle: A small prolog problem solved in haskell
header-img: "img/puzzle.jpg"
tags: [haskell, puzzle, algorithm]
tag_weights: [30,25,20]
redirect_from:
  - /posts/2011-08-09-hettsProblem.html
credits_name: boris drenec
credits_url: https://www.flickr.com/photos/_boris/
credits_license: https://creativecommons.org/licenses/by-nc-sa/2.0/
---

Found a neat little site on programming puzzles for prolog programmers today in my lunch break. Of course I needed to try one immediately! Just for the fun of it and to see if haskell is suitable for this *prolog* problems.

Here is the problem for the [prolog site](https://sites.google.com/site/prologsite/prolog-problems/1):

> 1.28 (**) Sorting a list of lists according to length of sublists  
> a) We suppose that a list (InList) contains elements that are lists themselves. The objective is to sort the elements of InList according to their length. E.g. short lists first, longer lists later, or vice versa.
> 
> Example:  
> ?- lsort([[a,b,c],[d,e],[f,g,h],[d,e],[i,j,k,l],[m,n],[o]],L).  
> L = [[o], [d, e], [d, e], [m, n], [a, b, c], [f, g, h], [i, j, k, l]]
> 

That does not seem to be a challenge. Start by importing some modules:

{% highlight haskell %}
import Data.List
import Data.Function
{% endhighlight %}

So the solution to the problem is actually just to find a suitable formulation in haskell:

{% highlight haskell %}
lsort = sortBy (compare `on` length)
{% endhighlight %}

Couldn't be more straight forward! Now move on to the second part:

> b) Again, we suppose that a list (InList) contains elements that are lists themselves. But this time the objective is to sort the elements of InList according to their length frequency; i.e. in the default, where sorting is done ascendingly, lists with rare lengths are placed first, others with a more frequent length come later.
> 
> Example:  
> ?- lfsort([[a,b,c],[d,e],[f,g,h],[d,e],[i,j,k,l],[m,n],[o]],L).  
> L = [[i, j, k, l], [o], [a, b, c], [f, g, h], [d, e], [d, e], [m, n]]
> 
> Note that in the above example, the first two lists in the result L have length 4 and 1, both lengths appear just once. The third and forth list have length 3; there are two list of this length. And finally, the last three lists have length 2. This is the most frequent length. 

Just a little more involved...but again, simple in haskell:

{% highlight haskell %}
lfsort xs = let ys = groupBy (\x y->length x == length y) (lsort xs) in
  concat $ sortBy (compare `on` length) ys
{% endhighlight %}

great! 3 lines in haskell to solve this! now back to work... :)

Full source-code is available [here](/code/hettsproblem/hett.hs).
