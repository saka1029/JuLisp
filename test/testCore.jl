@testset "Nil" begin
    @test "nil" == string(NIL)
    @test symbol("nil") != NIL
    @test null(NIL)
    @test !atom(NIL)
    @test !consp(NIL)
end

@testset "LispSymbol" begin
    @test symbol("a") == a
    @test "a" == string(a)
    @test !null(a)
    @test atom(a)
    @test !consp(a)
end

@testset "Cons" begin
    @test a == car(cons(a, b))
    @test b == cdr(cons(a, b))
    @test !null(cons(a, b))
    @test !atom(cons(a, b))
    @test consp(cons(a, b))
    @test NIL == list()
    @test cons(a, NIL) == list(a)
    @test cons(a, cons(b, NIL)) == list(a, b)
    @test "(a . b)" == string(cons(a, b))
    @test "(a b)" == string(cons(a, cons(b, NIL)))
    @test "'a" == string(cons(QUOTE, cons(a, NIL)))
    @test "(quote . a)" == string(cons(QUOTE, a))
    @test "'(a b)" == string(cons(QUOTE, cons(cons(a, cons(b, NIL)), NIL)))
end


@testset "Env" begin
    @test cons(b, c) == get(bind(a, a, bind(b, cons(b, c))), b)
    @test cons(a, b) == get(define(nothing, a, cons(a, b)), a)
    @test_throws ErrorException get(bind(a, a, bind(b, cons(b, c))), c)
    env = bind(a, a)
    @test cons(a, b) == set(env, a, cons(a, b))
    @test cons(a, b) == get(env, a)
end

@testset "evaluate" begin
    env = bind(QUOTE, special((s, x, e) -> car(x)))
    env = bind(symbol("car"), procedure(a -> a.car.car), env)
    env = bind(symbol("cdr"), procedure(a -> a.car.cdr), env)
    env = bind(symbol("cons"), procedure(a -> cons(a.car, a.cdr.car)), env)
    env = bind(symbol("list"), procedure(a -> a), env)
    @test a == evaluate(expression("'a"), env)
    @test a == evaluate(expression("(car '(a . b))"), env)
    @test b == evaluate(expression("(cdr '(a . b))"), env)
    @test cons(a, b) == evaluate(expression("(cons 'a 'b)"), env)
    @test cons(a, NIL) == evaluate(expression("(cons 'a nil)"), env)
    @test list(a, b, c) == evaluate(expression("(list 'a 'b 'c)"), env)
end

@testset "Closure" begin
    env = bind(QUOTE, special((s, x, e) -> car(x)))
    env = bind(symbol("car"), procedure(a -> a.car.car), env)
    env = bind(symbol("cdr"), procedure(a -> a.car.cdr), env)
    env = bind(symbol("cons"), procedure(a -> cons(a.car, a.cdr.car)), env)
    env = bind(symbol("list"), procedure(a -> a), env)
    env = bind(symbol("kar"), closure(list(a), expression("((car a))"), env), env)
    @test a == evaluate(expression("(kar '(a . b))"), env) 
end
