@testset "expression" begin
    @test a == expression("a")
    @test cons(a, b) == expression("(a . b)")
    @test list(a, b) == expression("(a b)")
    @test list(QUOTE, a) == expression("'a")
    @test list(QUOTE, list(a, b)) == expression("'(a b)")
end
