using JuLisp
using Test

a = symbol("a")
b = symbol("b")
c = symbol("c")
d = symbol("d")

@testset "LispSymbol" begin
    @test T == symbol("t")
    @test QUOTE == symbol("quote")
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

@testset "Pair" begin
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
    @test "'a" == string(cons(QUOTE, cons(a, NIL)))
    @test "(quote . a)" == string(cons(QUOTE, a))
    @test "'(a b)" == string(cons(QUOTE, cons(cons(a, cons(b, NIL)), NIL)))
end


@testset "env" begin
    e = env()
    define(e, b, cons(b, c))
    define(e, a, a)
    @test a          == get(e, a)
    @test cons(b, c) == get(e, b)
    define(e, a, cons(a, b))
    @test cons(a, b) == get(e, a)
    e = env()
    define(e, b, cons(b, c))
    @test_throws ErrorException get(e, c)
    e = env()
    define(e, a, a)
    define(e, a, cons(a, b))
    @test cons(a, b) == get(e, a)
end

@testset "evaluate" begin
    e = defaultEnv()
    @test a == evaluate(lispRead("'a"), e)
    @test a == evaluate(lispRead("(car '(a . b))"), e)
    @test b == evaluate(lispRead("(cdr '(a . b))"), e)
    @test cons(a, b) == evaluate(lispRead("(cons 'a ' b)"), e)
    @test cons(a, NIL) == evaluate(lispRead("(cons 'a nil)"), e)
    @test list(a, b, c) == evaluate(lispRead("(list 'a 'b 'c)"), e)
end

@testset "Closure" begin
    e = defaultEnv()
    @test a == evaluate(lispRead("((lambda (a) (car a)) '(a . b))"), e)
    define(e, symbol("kar"), closure(list(a), lispRead("((car a))"), e))
    @test a == evaluate(lispRead("(kar '(a . b))"), e) 
    @test b == evaluate(lispRead("(define a 'b)"), e)
    @test b == evaluate(a, e)
    evaluate(lispRead("(define kons (lambda (a b) (cons a b)))"), e)
    @test cons(a, b) == evaluate(lispRead("(kons 'a 'b)"), e)
end

@testset "repl" begin
    proc(e::String) = repl(LispReader(e), IOBuffer(), "")
    @test "t\n" == String(take!(proc("(atom 'a)")))
end

@testset "append" begin
    e = defaultEnv()
    evaluate(lispRead("""
        (define append
            (lambda (a b)
             (if (null a)
                 b
                 (cons (car a) (append (cdr a) b))  )))
          """), e)
    @test list(a, b, c, d) == evaluate(lispRead("(append '(a b) '(c d))"), e)
end

