@testset "lisp" begin
    @test a == lisp("a")
    @test cons(a, b) == lisp("(a . b)")
    @test list(a, b) == lisp("(a b)")
    @test list(QUOTE, a) == lisp("'a")
    @test list(QUOTE, list(a, b)) == lisp("'(a b)")
end