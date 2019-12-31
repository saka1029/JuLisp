using JuLisp
using Test

a = symbol("a")
b = symbol("b")
c = symbol("c")

@testset "LispSymbol" begin
    @test T == symbol("t")
    @test QUOTE == symbol("quote")
    @test LAMBDA == symbol("lambda")
    @test symbol("a") == symbol("a")
end

@testset "NIL" begin
    @test NIL == symbol("nil")
    @test "nil" == string(NIL)
    @test null(NIL)
    @test atom(NIL)
end

@testset "T" begin
    @test T == symbol("t")
    @test "t" == string(T)
    @test !null(T)
    @test atom(T)
end

@testset "LispSymbol" begin
    @test symbol("a") == a
    @test "a" == string(a)
    @test !null(a)
    @test atom(a)
end

@testset "Cons" begin
    @test a == car(cons(a, b))
    @test b == cdr(cons(a, b))
    @test !null(cons(a, b))
    @test !atom(cons(a, b))
    @test NIL == list()
    la = list(a)
    @test a == car(la)
    @test NIL == cdr(la)
    @test cons(a, NIL) == list(a)
    @test cons(a, cons(b, NIL)) == list(a, b)
    @test "(a . b)" == string(cons(a, b))
    @test "(a b)" == string(cons(a, cons(b, NIL)))
    @test "(quote a)" == string(cons(QUOTE, cons(a, NIL)))
    @test "(quote . a)" == string(cons(QUOTE, a))
    @test "(quote (a b))" == string(cons(QUOTE, cons(cons(a, cons(b, NIL)), NIL)))
end


@testset "env" begin
    @test list(cons(a, a), cons(b, cons(b, c))) == define(define(NIL, b, cons(b, c)), a, a)
    @test a          == get(define(define(NIL, b, cons(b, c)), a, a), a)
    @test cons(b, c) == get(define(define(NIL, b, cons(b, c)), a, a), b)
    @test cons(a, b) == get(define(NIL, a, cons(a, b)), a)
    @test_throws ErrorException get(define(NIL, b, cons(b, c)), c)
    env = define(NIL, a, a)
    @test cons(a, b) == set(env, a, cons(a, b))
    @test cons(a, b) == get(env, a)
end

@testset "evaluate" begin
    env = NIL
    env = define(env, NIL, NIL)
    env = define(env, QUOTE, special((s, x, e) -> car(x)))
    env = define(env, symbol("car"), procedure(a -> a.car.car))
    env = define(env, symbol("cdr"), procedure(a -> a.car.cdr))
    env = define(env, symbol("cons"), procedure(a -> cons(a.car, a.cdr.car)))
    env = define(env, symbol("list"), procedure(a -> a))
    @test a == evaluate(expression("(quote a)"), env)
    @test a == evaluate(expression("(car (quote (a . b)))"), env)
    @test b == evaluate(expression("(cdr (quote (a . b)))"), env)
    @test cons(a, b) == evaluate(expression("(cons (quote a) (quote b))"), env)
    @test cons(a, NIL) == evaluate(expression("(cons (quote a) nil)"), env)
    @test list(a, b, c) == evaluate(expression("(list (quote a) (quote b) (quote c))"), env)
end

#@testset "Closure" begin
#    env = bind(QUOTE, special((s, x, e) -> car(x)))
#    env = bind(symbol("car"), procedure(a -> a.car.car), env)
#    env = bind(symbol("cdr"), procedure(a -> a.car.cdr), env)
#    env = bind(symbol("cons"), procedure(a -> cons(a.car, a.cdr.car)), env)
#    env = bind(symbol("list"), procedure(a -> a), env)
#    env = bind(symbol("kar"), closure(list(a), expression("((car a))"), env), env)
#    @test a == evaluate(expression("(kar '(a . b))"), env) 
#end
#
#@testset "Processor" begin
#    p = processor(LispReader("t"))
#    process(p)
#end

@testset "expression" begin
    @test a == expression("a")
    @test cons(a, b) == expression("(a . b)")
    @test list(a, b) == expression("(a b)")
    @test list(QUOTE, a) == expression("(quote a)")
    @test list(QUOTE, list(a, b)) == expression("(quote (a b))")
end
