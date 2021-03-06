@test sort([2,3,1]) == [1,2,3]
@test sort([2,3,1], rev=true) == [3,2,1]
@test sortperm([2,3,1]) == [3,1,2]
@test !issorted([2,3,1])
@test issorted([1,2,3])
@test reverse([2,3,1]) == [1,3,2]
@test select([3,6,30,1,9],3) == 6
@test select([3,6,30,1,9],3:4) == [6,9]
@test sum(randperm(6)) == 21
@test nthperm([0,1,2],3) == [1,0,2]

@test searchsorted([1, 1, 2, 2, 3, 3], 0) == 1:0
@test searchsorted([1, 1, 2, 2, 3, 3], 1) == 1:2
@test searchsorted([1, 1, 2, 2, 3, 3], 2) == 3:4
@test searchsorted([1, 1, 2, 2, 3, 3], 4) == 7:6
@test searchsorted([1.0, 1, 2, 2, 3, 3], 2.5) == 5:4

for (rg,I) in {(49:57,47:59), (1:2:17,-1:19), (-3:0.5:2,-5:.5:4), (3+0*(1:5),-5:.5:4)}
    rg_r = reverse(rg)
    rgv, rgv_r = [rg], [rg_r]
    for i = I
        @test searchsorted(rg,i) == searchsorted(rgv,i)
        @test searchsorted(rg_r,i,rev=true) == searchsorted(rgv_r,i,rev=true)
    end
end

rg = 0.0:0.01:1.0
for i = 2:101
    @test searchsorted(rg, rg[i]) == i:i
    @test searchsorted(rg, prevfloat(rg[i])) == i:i-1
    @test searchsorted(rg, nextfloat(rg[i])) == i+1:i
end

rg_r = reverse(rg)
for i = 1:100
    @test searchsorted(rg_r, rg_r[i], rev=true) == i:i
    @test searchsorted(rg_r, prevfloat(rg_r[i]), rev=true) == i+1:i
    @test searchsorted(rg_r, nextfloat(rg_r[i]), rev=true) == i:i-1
end

a = rand(1:10000, 1000)

for alg in [InsertionSort, MergeSort]
    b = sort(a, alg=alg)
    @test issorted(b)
    ix = sortperm(a, alg=alg)
    b = a[ix]
    @test issorted(b)
    @test a[ix] == b

    b = sort(a, alg=alg, rev=true)
    @test issorted(b, rev=true)
    ix = sortperm(a, alg=alg, rev=true)
    b = a[ix]
    @test issorted(b, rev=true)
    @test a[ix] == b

    b = sort(a, alg=alg, by=x->1/x)
    @test issorted(b, by=x->1/x)
    ix = sortperm(a, alg=alg, by=x->1/x)
    b = a[ix]
    @test issorted(b, by=x->1/x)
    @test a[ix] == b

    c = copy(a)
    permute!(c, ix)
    @test c == b

    ipermute!(c, ix)
    @test c == a

    c = sort(a, alg=alg, lt=(>))
    @test b == c

    c = sort(a, alg=alg, by=x->1/x)
    @test b == c
end

b = sort(a, alg=QuickSort)
@test issorted(b)
b = sort(a, alg=QuickSort, rev=true)
@test issorted(b, rev=true)
b = sort(a, alg=QuickSort, by=x->1/x)
@test issorted(b, by=x->1/x)

@test select([3,6,30,1,9], 2, rev=true) == 9
@test select([3,6,30,1,9], 2, by=x->1/x) == 9

## more advanced sorting tests ##

randnans(n) = reinterpret(Float64,[rand(Uint64)|0x7ff8000000000000 for i=1:n])

function randn_with_nans(n,p)
    v = randn(n)
    x = find(rand(n).<p)
    v[x] = randnans(length(x))
    return v
end

srand(0xdeadbeef)

for n in [0:10, 100, 101, 1000, 1001]
    r = 1:10
    v = rand(1:10,n)
    h = hist(v,r)

    for ord in [Base.Order.Forward, Base.Order.Reverse]
        # insertion sort (stable) as reference
        pi = sortperm(v, alg=InsertionSort, order=ord)
        @test isperm(pi)
        si = v[pi]
        @test hist(si,r) == h
        @test issorted(si, order=ord)
        @test all(issorted,[pi[si.==x] for x in r])
        c = copy(v)
        permute!(c, pi)
        @test c == si
        ipermute!(c, pi)
        @test c == v

        # stable algorithms
        for alg in [MergeSort]
            p = sortperm(v, alg=alg, order=ord)
            @test p == pi
            s = copy(v)
            permute!(s, p)
            @test s == si
            ipermute!(s, p)
            @test s == v
        end

        # unstable algorithms
        for alg in [QuickSort]
            p = sortperm(v, alg=alg, order=ord)
            @test isperm(p)
            @test v[p] == si
            s = copy(v)
            permute!(s, p)
            @test s == si
            ipermute!(s, p)
            @test s == v
        end
    end

    v = randn_with_nans(n,0.1)
    for ord in [Base.Order.Forward, Base.Order.Reverse],
        alg in [InsertionSort, QuickSort, MergeSort]
        # test float sorting with NaNs
        s = sort(v, alg=alg, order=ord)
        @test issorted(s, order=ord)
        @test reinterpret(Uint64,v[isnan(v)]) == reinterpret(Uint64,s[isnan(s)])

        # test float permutation with NaNs
        p = sortperm(v, alg=alg, order=ord)
        @test isperm(p)
        vp = v[p]
        @test isequal(vp,s)
        @test reinterpret(Uint64,vp) == reinterpret(Uint64,s)
    end
end
