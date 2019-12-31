module JuLisp

import Base.==, Base.show, Base.get, Base.Iterators

export null, atom
export NIL, T, QUOTE, LAMBDA
export symbol
export cons, car, cdr, list
export get, define, set
export special, procedure, evaluate
export closure
export LispReader, expression

abstract type Object end

struct LispSymbol <: Object
    symbol::Symbol
end
symbol(name::String) = LispSymbol(Symbol(name))
const NIL = symbol("nil")
const T = symbol("t")
const QUOTE = symbol("quote")
const LAMBDA = symbol("lambda")
const EOF = symbol("*EOF*")
atom(e::LispSymbol) = true
null(e::Object) = e == NIL
show(io::IO, e::LispSymbol) = print(io, e.symbol)

evaluate(variable::LispSymbol, env::Object) = get(env, variable)

abstract type ConstObject <: Object end

mutable struct Cons <: Object
    car::Object
    cdr::Object
end
atom(e::Cons) = false
cons(a::Object, b::Object) = Cons(a, b)
car(e::Cons) = e.car
cdr(e::Cons) = e.cdr
(==)(a::Cons, b::Cons) = a.car == b.car && b.cdr == b.cdr

function list(args::Object...)
    r = NIL
    for e in reverse(args)
        r = cons(e, r)
    end
    return r
end

function find(env::Object, variable::LispSymbol)
    while env != NIL
        if variable == env.car.car
            return env.car
        end
        env = env.cdr
    end
    error("Variable $variable not found")
end

get(env::Object, variable::LispSymbol) = find(env, variable).cdr

define(env::Object, variable::LispSymbol, value::Object) = Cons(Cons(variable, value), env)

set(env::Object, variable::LispSymbol, value::Object) = find(env, variable).cdr = value

struct Applicable <: Object
    apply::Function
end

special(f::Function) = Applicable(f)

evlis(args::Object, env::Object) = args isa Cons ? Cons(evaluate(args.car, env), evlis(args.cdr, env)) : NIL

procedure(f::Function) = Applicable((this, args, env) -> f(evlis(args, env)))

function evaluate(e::Cons, env::Object)
    f = evaluate(e.car, env)
    f.apply(f, e.cdr, env)
end

function show(io::IO, e::Cons)
    x::Object = e
    print(io, "(")
    sep = ""
    while x isa Cons
        print(io, sep, x.car)
        sep = " "
        x = x.cdr
    end
    if x != NIL
        print(io, " . ", x)
    end
    print(io, ")")
end

struct Closure <: Object
    parms::Object
    body::Object
    env::Object
    apply::Function
end

function closureApply(closure::Closure, args::Object, env::Object)
    function pairlis(parms::Object, args::Object, env::Object)
        while (parms isa Cons)
            env = define(env, parms.car, args.car)
            parms = parms.cdr
            args = args.cdr
        end
        if parms != NIL
            env = define(env, parms, args)
        end
        return env
    end

    function progn(body::Object, env::Object)
        if body.cdr == NIL
            r = evaluate(body.car, env)
            return r
        end
        evaluate(body.car, env)
        return progn(body.cdr, env)
    end

    n = pairlis(closure.parms, evlis(args, env), closure.env)
    return progn(closure.body, n)
end

function closure(parms::Object, body::Object, env::Object)
    Closure(parms, body, env, closureApply)
end



mutable struct LispReader
    in::IO
    ch::Char
end

function getch(r::LispReader)
    if eof(r.in)
        r.ch = '\uFFFF'
    else
        r.ch = read(r.in, Char)
    end
    r.ch
end

function LispReader(in::IO)
    r = LispReader(in, '\uFFFF')
    getch(r)
    r
end

function LispReader(s::String)
    LispReader(IOBuffer(s))
end

function Base.read(r::LispReader)

    DOT = symbol(".")

    function skipSpaces()
        while isspace(r.ch)
            getch(r)
        end
    end

    function makeList(elements, last::Object)
        if last == NIL
            list(elements...)
        else
            for e in reverse(elements)
                last = cons(e, last)
            end
            return last
        end
    end

    function readList()
        elements = Array{Object, 1}()
        last = NIL
        while true
            skipSpaces()
            if r.ch == ')'
                getch(r)
                return makeList(elements, last)
            elseif r.ch == '\uFFFF'
                error(") expected")
            else
                e = readObject()
                if e == DOT
                    last = read(r)
                    skipSpaces()
                    if r.ch != ')'
                        error(") expected")
                    end
                    getch(r)
                    return makeList(elements, last)
                end
                push!(elements, e)
            end
        end
    end

    isdelim(c::Char) = occursin(c,  "'(),\"")

    issymbol(c::Char) = c != '\uFFFF' && !isspace(c) && !isdelim(c)

    function readSymbol(s::String)
        while issymbol(r.ch)
            s *= r.ch
            getch(r)
        end
        return symbol(s)
    end

    function readAtom()
        first = r.ch
        s = "" * first
        getch(r)
        if first == '+' || first == '-'
            return isdigit(r.ch) ? readNumber(s) : readSymbol(s)
        elseif first == '.'
            return issymbol(r.ch) ? readSymbol(s) : DOT
        else
            return readSymbol(s)
        end
    end

    function readObject()
        skipSpaces()
        if r.ch == '\uFFFF'
            return EOF
        elseif r.ch == '('
            getch(r)
            return readList()
        else
            return readAtom()
        end
    end

    obj = readObject()
    if obj == DOT
        error("unexpected '.'")
    end
    return obj
end

expression(s::String) = read(LispReader(s))

#include("processor.jl")

end # module
