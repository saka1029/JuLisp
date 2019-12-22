import Base.show, Base.get, Base.bind

export null, atom, consp
export QUOTE, NIL, T
export symbol
export cons, car, cdr, list
export bind, get, define, set
export special, procedure, evaluate
export closure

abstract type Object end

abstract type Atom <: Object end
null(e::Atom) = false
atom(e::Atom) = true
consp(e::Atom) = false

struct LispSymbol <: Atom
    name::Symbol
end
symbol(name::String) = LispSymbol(Symbol(name))
show(io::IO, e::LispSymbol) = print(io, e.name)
const QUOTE = symbol("quote")
const LAMBDA = symbol("lambda")
const EOF = symbol("*EOF*")

mutable struct Bind
    variable::LispSymbol
    value::Object
    next::Union{Bind, Nothing}
end
Env = Union{Bind, Nothing}

bind(variable::LispSymbol, value::Object, e::Env) = Bind(variable, value, e)
bind(variable::LispSymbol, value::Object) = Bind(variable, value, nothing)

function find(env::Env, variable::LispSymbol)
    while env != nothing
        if variable == env.variable
            return env
        end
        env = env.next
    end
    error("Variable $variable not found")
end

function get(env::Env, variable::LispSymbol)
    find(env, variable).value
end

function define(env::Env, variable::LispSymbol, value::Object)
    Bind(variable, value, env)
end

function set(env::Env, variable::LispSymbol, value::Object)
    find(env, variable).value = value
end

evaluate(variable::LispSymbol, env::Env) = get(env, variable)

abstract type ConstObject <: Object end

struct Nil <: ConstObject end
null(e::Nil) = true
atom(e::Nil) = false
consp(e::Nil) = false
show(io::IO, e::Nil) = print(io, "nil")
const NIL = Nil()
evaluate(obj::ConstObject, env::Env) = obj

struct True <: ConstObject end
null(e::True) = false
atom(e::True) = true
consp(e::True) = false
show(io::IO, e::True) = print(io, "t")
const T = True()

struct Cons <: Object
    car::Object
    cdr::Object
end
null(e::Cons) = false
atom(e::Cons) = false
consp(e::Cons) = true
cons(a::Object, b::Object) = Cons(a, b)
car(e::Cons) = e.car
cdr(e::Cons) = e.cdr
function list(args::Object...)
    r = NIL
    for e in Iterators.reverse(args)
        r = Cons(e, r)
    end
    r
end

struct Special <: Object
    apply::Function
end
special(f::Function) = Special(f)

function evlis(args::Object, env::Env)
    args isa Cons ? cons(evaluate(args.car, env), evlis(args.cdr, env)) : NIL
end

function procedure(f::Function)
    Special((this, args, env) -> f(evlis(args, env)))
end

function evaluate(e::Cons, env::Env)
    f = evaluate(e.car, env)
    f.apply(f, e.cdr, env)
end

function show(io::IO, e::Cons)
    if e.cdr isa Cons && e.cdr.cdr isa Nil
        if e.car == QUOTE
            print(io, "'", e.cdr.car)
            return
        end
    end
    x::Object = e
    print(io, "(")
    sep = ""
    while x isa Cons
        print(io, sep, x.car)
        sep = " "
        x = x.cdr
    end
    if !(x isa Nil)
        print(io, " . ", x)
    end
    print(io, ")")
end

struct Closure <: Object
    parms::Object
    body::Object
    env::Env
    apply::Function
end

function closureApply(closure::Closure, args::Object, env::Env)
    function pairlis(parms::Object, args::Object, env::Env)
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

    function progn(body::Object, env::Env)
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

function closure(parms::Object, body::Object, env::Env)
    Closure(parms, body, env, closureApply)
end
