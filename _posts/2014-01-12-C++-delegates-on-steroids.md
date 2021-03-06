---
layout:     post
title: "C++ Delegates On Steroids"
subtitle: Generic version of impossibly fast delegate using C++11 variadic templates.
date:       2014-01-12 12:00:00
author:     "Oliver Mueller"
header-img: "img/shuttlestart.jpg"
future_categories: programming
tags: [C++, templates, lua]
tag_weights: [30,20,5]
redirect_from:
  - /posts/2014-01-12-C++-delegates-on-steroids.html
---

Yesterday I came across an [excellent article] from [Jeremy Ong] that introduces
an extremely nice solution for integrating C++ and Lua code. Jeremy used a
technique based on C++ meta-programming in conjunction with C++11 variadic
templates to call Lua functions from C++ code.  
That reminded me of some other example where variadic templates have been a joy
to work with: coding delegates in C++.

## Why Delegates?

<div class="jumbotron">

<h3>"Don't call us, we'll call you"</h3>

Delegates enable you to pass around callable entities without introducing a too
tight coupling that is usually the case when using interfaces in form of
abstract base classes. They are a little like function pointers in C but in a
more type-safe manner and do not only work for free functions but also for
member functions. As such they are well suited e.g. for systems that communicate
through events.

</div>


So why use delegates when you can also pass around objects that offer the
required virtual functions in their interface? This works but introduces too
many dependencies for my taste. What if you cannot change the interface of the
object you are using? By using delegates instead of an explicit interface the
requirements for client code are minimized. If you are implementing some kind of
asynchronous service, it's always a good idea to assume the least possible
amount about your users. The result is a more functional rather then object
oriented API.  
Further more, no virtual functions are needed whatsoever which can be important
when memory is scarce. The delegates I am talking about have a compile time
interface only.

## First Implementation

Before starting of I'd like to mention that the whole idea behind this delegate
implementation originates from [Sergey Ryazanov] who wrote an excellent article
about [the impossibly fast c++ delegate]. It is by no means complete but
hopefully conveys the underlying ideas as well as the motivation for using
variadic templates.  
The goals for Sergey's implementation were:

* performance (the faster the better)
* no dynamic memory allocation
* compatible with the C++ Standard

Exactly the things that were also important to my usage (mainly in embedded
systems programming) where dynamic memory allocation is often not possible.  
The trick for a Delegate implementation is that the code that will end up
calling back your delegate must not have any type dependencies to the code that
implements the callback function. In Sergeys implementation a Delegate will
store an *untyped pointer to an object* and a *member-function-pointer*.  
Here is a first sketch for a fixed return type and a fixed parameter:

{% highlight cpp %}
class Delegate
{
    typedef void (*Type)(void* callee, int);
public:
    Delegate(void* callee, Type function)
        : fpCallee(callee)
        , fpCallbackFunction(function) {}

    template <class T, void (T::*TMethod)(int)>
    static Delegate from_function(T* callee)
    {
        Delegate d(callee, &methodCaller<T, TMethod>);
        return d;
    }

    void operator()(int x) const
    {
        return (*fpCallbackFunction)(fpCallee, x);
    }

private:

    void* fpCallee;
    Type fpCallbackFunction;

    template <class T, void (T::*TMethod)(int)>
    static void methodCaller(void* callee, int x)
    {
        T* p = static_cast<T*>(callee);
        return (p->*TMethod)(x);
    }
};
{% endhighlight %}

The `Delegate` class provides two public functions: the static `from_function`
is used to construct the delegate. Here the instance itself is stored along with
a `methodCaller` function pointer that casts the untyped stored pointer back to
it's original type. The function call operator will be used to invoke the
delegate.  
Notice that the compiler will bake in the type information about `T` so that
when the delegate is invoked it knows exactly about the types involved. Thus the
`static_cast` in the `methodCaller` is by no means unsafe.

### Checking Equality

Delegates can freely be passed around and copied since the data is only 2
pointers. Checking if one delegate corresponds to another can be easily
achieved.

{% highlight cpp %}
bool operator==(const Delegate& other) const
{
    return (fpCallee == other.fpCallee)
           && (fpCallbackFunction == other.fpCallbackFunction);
}
{% endhighlight %}

### Usage

How can this implementation be used in real code? Say you have a class `A` with
a function `foo` that you want to pass to some other code.

{% highlight cpp %}
class A
{
public:
    void foo(int x)
    {
        printf("foo called with x=%d\n", x);
    }
    void bar(int x) {}
};
int main()
{
    A a;
    Delegate d = Delegate::from_function<A, &A::foo>(&a);
    d(42);
    printf("d==d: %s\n", d == d ? "True" : "False");
    Delegate d2 = Delegate::from_function<A, &A::bar>(&a);
    printf("d==d2: %s\n", d == d2 ? "True" : "False");
    return 0;
}
{% endhighlight %}

First you of course need an object of `A` (`a`). Constructing the delegate
involves a call to the `from_function` function that takes the type of `a` and
the member function pointer as template arguments plus `a` as a normal argument.
Then the delegate is ready to be passed around and used.

## A more Generic Version

Our first implementation has one severe drawback: It only works for a very
special function signature for the delegate function.  
What we would like to have is a delegate for all possible combinations of return
values and argument types.

### Parameter for Return Type and Argument

As a first step, let's make the `Delegate` class a template so that we can vary
the return type and one parameter type.

{% highlight cpp %}
template<typename return_type, typename param_type>
class Delegate
{
    typedef return_type (*Type)(void* callee, param_type);
public:
    Delegate(void* callee, Type function)
        : fpCallee(callee)
        , fpCallbackFunction(function) {}

    template <class T, return_type (T::*TMethod)(param_type)>
    static Delegate from_function(T* callee)
    {
        Delegate d(callee, &methodCaller<T, TMethod>);
        return d;
    }

    return_type operator()(param_type x) const
    {
        return (*fpCallbackFunction)(fpCallee, x);
    }

private:

    void* fpCallee;
    Type fpCallbackFunction;

    template <class T, return_type (T::*TMethod)(param_type)>
    static return_type methodCaller(void* callee, param_type x)
    {
        T* p = static_cast<T*>(callee);
        return (p->*TMethod)(x);
    }
};
{% endhighlight %}

### Usage

{% highlight cpp %}
class A
{
public:
    int foo(int x)
    {
        return x*x;
    }
};
int main()
{
    A a;
    typedef Delegate<int, int> IntDelegate;
    IntDelegate d = IntDelegate::from_function<A, &A::foo>(&a);
    printf("calling delegate with return value: d(42)=%d\n", d(42));
    return 0;
}
{% endhighlight %}

While this is a little more flexible, we are still not at our goal for a truly generic delegate implementation.

## Meet Variadic Templates

Variadic templates solve a long standing problem in C++ when working with templates. They finally allow the user to define template-classes and template-functions that can work with an arbitrarily long list of template arguments. Previously you had to write or pre-generate template specializations for multiple arguments, s.th. that for example needed to be done excessively in template-heavy boost libraries. Using variadic templates things can now be written much more smoothly.  
This new feature shows up in form of *parameter packs* in your template definitions:

{% highlight cpp %}
template <typename... Ts>
class A
{};

template <typename... Ts>
void foo(Ts... vs)
{}
{% endhighlight %}

Here, `Ts` is a synonym for a *list of types* (not a single type!) and `vs` stands for a *list of values*. To work with them you can re-expand those lists in your code.

### Expansions

To help to understand what parameter packs get expanded to, it's easiest to look at the following expansions that the compiler will take care of:

<table class="table borderless">
  <tbody>
    <tr class="odd">
      <td align="left"><code>Ts...</code></td>
      <td align="left">→</td>
      <td align="left">T<sub>1</sub>,…T<sub>n</sub></td>
    </tr>
    <tr class="even">
      <td align="left"><code>x&lt;Ts, Y&gt;::z...</code></td>
      <td align="left">→</td>
      <td align="left">x&lt;T<sub>1</sub>, Y&gt;::z,… x&lt;T<sub>n</sub>, Y&gt;::z</td>
    </tr>
    <tr class="odd">
      <td align="left"><code>x&lt;Ts&amp;, Us&gt;...</code></td>
      <td align="left">→</td>
      <td align="left">x&lt;T<sub>1</sub>&amp;, U<sub>1</sub>&gt;,… x&lt;T<sub>n</sub>&amp;, U<sub>n</sub>&gt;</td>
    </tr>
    <tr class="even">
      <td align="left"><code>foo(vs)...</code></td>
      <td align="left">→</td>
      <td align="left">foo(v1),… foo(vn)</td>
    </tr>
  </tbody>
</table>

The `...` ellipsis makes the compiler look to its left side to figure out what
can be expanded. In the first case it's just a list of types. More interesting
in the second case, here `Ts` is expandable but not `Y` so the whole expression
will be expanded for the `Ts`.  
When there is more than one possibility to expand, all possible matches will be
expanded together (T<sub>1</sub> with U<sub>1</sub>, T<sub>2</sub> with
U<sub>2</sub> and so on).  
Expansion also works for lists of values when e.g. calling a function with every
element in a list.

### Example

[Andrei] had a nice little example in [his talk at GoingNative 2012] that shows
a simple function that makes use of variadic templates.

{% highlight cpp %}
template <class T1, class T2>
bool isOneOf(T1&& a, T2&& b)
{
    return a == b;
}
template <class T1, class T2, class... Ts>
bool isOneOf(T1&& a, T2&& b, Ts&& ... vs)
{
    return a == b || isOneOf(a, vs...);
}
...
bool res = isOneOf(1, 2, 3.5, 4, 1, 2);
{% endhighlight %}

This function takes a list of arguments (at least 2) and checks if the first
argument gets repeated somewhere.

## Truly Generic Delegate

Now with the nice addition of variadic templates it's possible to write a true
generic version for our delegate, i.e. a delegate that is both parameterized in
it's return type and it's argument types.

{% highlight cpp %}
template<typename return_type, typename... params>
class Delegate
{
    typedef return_type (*Type)(void* callee, params...);
public:
    Delegate(void* callee, Type function)
        : fpCallee(callee)
        , fpCallbackFunction(function) {}

    template <class T, return_type (T::*TMethod)(params...)>
    static Delegate from_function(T* callee)
    {
        Delegate d(callee, &methodCaller<T, TMethod>);
        return d;
    }

    return_type operator()(params... xs) const
    {
        return (*fpCallbackFunction)(fpCallee, xs...);
    }

private:

    void* fpCallee;
    Type fpCallbackFunction;

    template <class T, return_type (T::*TMethod)(params...)>
    static return_type methodCaller(void* callee, params... xs)
    {
        T* p = static_cast<T*>(callee);
        return (p->*TMethod)(xs...);
    }
};
{% endhighlight %}

### Usage

{% highlight cpp %}
class A
{
public:
    int foo(int x)
    {
        return x*x;
    }
    int bar(int x, int y, char a)
    {
        return x*y;
    }
};
int main()
{
    A a;
    auto d = Delegate<int, int>::from_function<A, &A::foo>(&a);
    auto d2 = Delegate<int, int, int, char>::from_function<A, &A::bar>(&a);
    printf("delegate with return value: d(42)=%d\n", d(42));
    printf("for d2: d2(42, 2, 'a')=%d\n", d2(42, 2, 'a'));
    return 0;
}
{% endhighlight %}

Finally we have Delegate available for all the function types we want to use on
our delegate objects. Ok, the syntax might be a little verbose but that can be
amended somewhat using a factory function for our delegates in combination with
a little C macro.

### Syntactic Sugar please!

Let's see what we can do to make delegates a little more pleasing to the eye:

{% highlight cpp %}
template<typename return_type, typename... params>
class Delegate
{
    ...
};

template<typename T, typename return_type, typename... params>
struct DelegateMaker
{
    template<return_type (T::*foo)(params...)>
    static return_type methodCaller(void* o, params... xs)
    {
        return (static_cast<T*>(o)->*foo)(xs...);
    }

    template<return_type (T::*foo)(params...)>
    inline static Delegate<return_type, params...> Bind(T* o)
    {
        return Delegate<return_type,
               params...>(o, &DelegateMaker::methodCaller<foo>);
    }
};

template<typename T, typename return_type, typename... params>
DelegateMaker<T, return_type, params... >
makeDelegate(return_type (T::*)(params...))
{
    return DelegateMaker<T, return_type, params...>();
}

#define DELEGATE(foo, thisPrt) (makeDelegate(foo).Bind<foo>(thisPrt))

{% endhighlight %}

Puuhh...looks worse than it is since this is only library code that users of our
delegate implementation will never need to look at. The `DelegateMaker` together
with the `makeDelegate` function is needed to make use of C++'s template
argument deduction which unfortunately only works on template functions and not
class templates. But now we can easily have our cake and eat it, too.

### Usage

{% highlight cpp %}
class A
{
public:
    void deadSimple()
    {
        printf("no params whatsoever\n");
    }
    int foo(int x)
    {
        return x*x;
    }
    int bar(int x, int y, char a)
    {
        return a == 'a' ? x+y : x*y;
    }
    void crazy(int I, char wanna, float go, const char* crazy)
    {
        printf("I=%d, wanna=%c, go=%f, crazy=%s\n",
               I, wanna, go, crazy);
    }
};
int main()
{
    A a;
    auto d = DELEGATE(&A::foo, &a);
    auto d2 = DELEGATE(&A::bar, &a);
    auto d3 = DELEGATE(&A::crazy, &a);
    auto d4 = DELEGATE(&A::deadSimple, &a);
    printf("d(42)=%d\n", d(42));
    printf("d2(42, 2, 'a')=%d\n", d2(42, 2, 'a'));
    const char* s = "sheeeet!";
    d3(5, 'a', 4.5, s);
    d4();
    return 0;
}
{% endhighlight %}

There you go. An extremely fast delegate implementation that looks quite usable
to my eyes thanks to C++11's variadic templates.

---

If you are interested, the source-code is available on [github].

[the impossibly fast c++ delegate]:http://www.codeproject.com/Articles/11015/The-Impossibly-Fast-C-Delegates
[Sergey Ryazanov]:http://www.codeproject.com/Members/Sergey-Ryazanov
[Andrei]:http://erdani.com/
[his talk at GoingNative 2012]:http://channel9.msdn.com/Events/GoingNative/GoingNative-2012/Variadic-Templates-are-Funadic
[excellent article]:http://www.jeremyong.com/blog/2014/01/10/interfacing-lua-with-templates-in-c-plus-plus-11/
[Jeremy Ong]:https://github.com/jeremyong
[github]:https://github.com/marcmo/delegates
