module JuLisp

import Base.==, Base.show, Base.get, Base.Iterators

export null, atom
export NIL, T, QUOTE
export symbol
export cons, car, cdr, list
export env, get, define, set
export special, procedure, evaluate
export closure
export LispReader, lispRead, repl

"Lispオブジェクトの抽象型です"
abstract type Object end

"Lispにおけるシンボルの型です"
struct Sym <: Object
    symbol::Symbol
end
symbol(name::String) = Sym(Symbol(name))
const NIL = symbol("nil")
const T = symbol("t")
const QUOTE = symbol("quote")
const END_OF_EXPRESSION = symbol("*end-of-expression*")
null(e::Object) = e == NIL
atom(e::Sym) = true
show(io::IO, e::Sym) = print(io, e.symbol)

struct Pair <: Object
    car::Object
    cdr::Object
end
atom(e::Pair) = false
cons(a::Object, b::Object) = Pair(a, b)
car(e::Pair) = e.car
cdr(e::Pair) = e.cdr
function list(args::Object...)
    r = NIL
    for e in reverse(args)
        r = Pair(e, r)
    end
    return r
end
function show(io::IO, e::Pair)
    x::Object = e
    print(io, "(")
    sep = ""
    while x isa Pair
        print(io, sep, x.car)
        sep = " "
        x = x.cdr
    end
    if x != NIL
        print(io, " . ", x)
    end
    print(io, ")")
end

"変数の束縛を保持する型です"
mutable struct Env
    bind::Object
end
env() = Env(NIL)

function find(env::Env, variable::Sym)
    bind = env.bind
    while bind != NIL
        if variable == bind.car.car
            return bind.car
        end
        bind = bind.cdr
    end
    error("Variable $variable not found")
end

get(env::Env, var) = find(env, var).cdr

function define(env::Env, var::Sym, val::Object)
    env.bind = Pair(Pair(var, val), env.bind) 
    return val
end

"Apply可能なLispオブジェクトの型です"
struct Applicable <: Object
    apply::Function
end

special(f::Function) = Applicable(f)

function evlis(args::Object, env::Env)
    args isa Pair ? Pair(evaluate(args.car, env), evlis(args.cdr, env)) : NIL 
end

"Lispの関数を作成する関数です"
function procedure(f::Function)
    Applicable((this, args, env) -> f(evlis(args, env)))
end

evaluate(variable::Sym, env::Env) = get(env, variable)

function evaluate(e::Pair, env::Env)
    a = evaluate(e.car, env)
    a.apply(a, e.cdr, env)
end

"クロージャです"
struct Closure <: Object
    parms::Object
    body::Object
    env::Env    # クロージャが定義された時の変数束縛
    apply::Function # クロージャの関数本体
end

function closureApply(closure::Closure, args::Object, env::Env)
    function pairlis(parms::Object, args::Object, env::Env)
        while (parms isa Pair)
            define(env, parms.car, args.car)
            parms = parms.cdr
            args = args.cdr
        end
        if parms != NIL
            define(env, parms, args)
        end
    end
    nenv = Env(closure.env.bind)
    pairlis(closure.parms, evlis(args, env), nenv)
    return evaluate(closure.body.car, nenv)
end

"クロージャを作成します"
closure(parms::Object, body::Object, env::Env) = Closure(parms, body, env, closureApply)

const EOF = '\uFFFF'

mutable struct LispReader
    in::IO
    ch::Char
end

getch(r::LispReader) = eof(r.in) ? r.ch = EOF : r.ch = read(r.in, Char)

function LispReader(in::IO)
    r = LispReader(in, EOF)
    getch(r)
    r
end

LispReader(s::String) = LispReader(IOBuffer(s))

function Base.read(r::LispReader)

    DOT = symbol(".")

    function skipSpaces()
        while isspace(r.ch)
            getch(r)
        end
    end

    function makeList(elements::Array{Object, 1}, last::Object)
        if last == NIL
            list(elements...)
        else
            for e in reverse(elements)
                last = Pair(e, last)
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
            elseif r.ch == EOF
                error(") expected")
            else
                e = readObject()
                if e == DOT
                    last = read(r)
                    skipSpaces()
                    if r.ch != ')'
                        error(") expected")
                    end
                    getch(r) # skip ')'
                    return makeList(elements, last)
                end
                push!(elements, e)
            end
        end
    end

    isdelim(c::Char) = occursin(c,  "'(),\"")
    issymbol(c::Char) = c != EOF && !isspace(c) && !isdelim(c)

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
        if first == '.'
            return issymbol(r.ch) ? readSymbol(s) : DOT
        else
            return readSymbol(s)
        end
    end

    function readObject()
        skipSpaces()
        if r.ch == EOF
            return END_OF_EXPRESSION
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

lispRead(s::String) = read(LispReader(s))


function repl(in::LispReader, out::IO, prompt::String)
    predicate(e::Bool) = e ? T : NIL
    e = env()
    define(e, NIL, NIL)
    define(e, T, T)
    define(e, QUOTE, special((s, a, e) -> a.car))
    define(e, symbol("atom"), procedure(a -> predicate(atom(a.car))))
    define(e, symbol("null"), procedure(a -> predicate(null(a.car))))
    define(e, symbol("car"), procedure(a -> a.car.car))
    define(e, symbol("cdr"), procedure(a -> a.cdr.car))
    define(e, symbol("cons"), procedure(a -> Pair(a.car, a.cdr.car)))
    define(e, symbol("define"), special((s, a, e) -> closure(a.car, a.cdr, e)))
    define(e, symbol("lambda"), special((s, a, e) -> define(e, a.car, evaluate(a.cdr.car, e))))
    while true
        print(out, prompt)
        flush(out)
        x = read(in)
#        println(out, "x=$x")
        if x == END_OF_EXPRESSION
            break
        end
        show(out, evaluate(x, e))
        println(out)
    end
    return out
end

end # module
