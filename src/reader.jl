export LispReader, expression

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

    function isdelim(c::Char)
        occursin(c,  "'(),\"")
    end

    function issymbol(c::Char)
        c != '\uFFFF' && !isspace(c) && !isdelim(c)
    end

    function readSymbol(s::String)
        while issymbol(r.ch)
            s *= r.ch
            getch(r)
        end
        s == "nil" ? NIL : s == "t" ? T : symbol(s)
    end

    function readNumber(s::String)
        while isdigit(r.ch)
            s *= r.ch
            getch(r)
        end
        return symbol(s)       # 数値を返すべきだがとりあえずSymbolを返す
    end

    function readAtom()
        first = r.ch
        s = "" * first
        getch(r)
        if first == '+' || first == '-'
            isdigit(r.ch) ? readNumber(s) : readSymbol(s)
        elseif first == '.'
            issymbol(r.ch) ? readSymbol(s) : DOT
        else
            isdigit(first) ? readNumber(s) : readSymbol(s)
        end
    end

    function readObject()
        skipSpaces()
        if r.ch == '\uFFFF'
            return EOF
        elseif r.ch == '('
            getch(r)
            return readList()
        elseif r.ch == '\''
            getch(r)
            return list(QUOTE, read(r))
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

function expression(s::String)
    read(LispReader(s))
end
