export processor, process

mutable struct Processor
    env::Env
    reader::LispReader
end

function initEnv(p::Processor)
    p.env = bind(QUOTE, special((s, x, e) -> car(x)), p.env)
    p.env = bind(symbol("null"), procedure(a -> null(a.car) ? T : NIL), p.env)
    p.env = bind(symbol("atom"), procedure(a -> atom(a.car) ? T : NIL), p.env)
    p.env = bind(symbol("consp"), procedure(a -> consp(a.car) ? T : NIL), p.env)
    p.env = bind(symbol("equal"), procedure(a -> a.car == a.cdr.car ? T : NIL), p.env)
    p.env = bind(symbol("car"), procedure(a -> a.car.car), p.env)
    p.env = bind(symbol("cdr"), procedure(a -> a.car.cdr), p.env)
    p.env = bind(symbol("cons"), procedure(a -> cons(a.car, a.car.cdr.car)), p.env)
    p.env = bind(symbol("list"), procedure(a -> a), p.env)
end

function processor(reader::LispReader)
    p = Processor(nothing, reader)
    initEnv(p)
    return p
end

function process(p::Processor)
    println(evaluate(read(p.reader), p.env))
end
