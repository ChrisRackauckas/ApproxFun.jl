


## Calculus

function Base.sum(f::Fun{JacobiWeight{Chebyshev}})
    α,β=f.space.α,f.space.β    
    if α <= -1.0 || β <= -1.0
        fs = Fun(f.coefficients,f.space.space)
        d = domain(fs)
        return Inf*fromcanonicalD(f,0.)*(sign(fs[d.a])+sign(fs[d.b]))/2
    else
        n = length(f)
        c = zeros(n)
        c[1] = 2.^(α+β+1)*gamma(α+1)*gamma(β+1)/gamma(α+β+2)
        if n > 1
            c[2] = c[1]*(α-β)/(α+β+2)
            for i=1:n-2
                c[i+2] = (2(α-β)*c[i+1]-(α+β-i+2)*c[i])/(α+β+i+2)
            end
        end
        return fromcanonicalD(f,0.)*dot(f.coefficients,c)
    end
end

function differentiate{J<:JacobiWeight}(f::Fun{J})
    S=f.space
    d=domain(f)    
    ff=Fun(f.coefficients,S.space)    
    if S.α==S.β==0
        u=differentiate(ff)
        Fun(u.coefficients,JacobiWeight(0.,0.,space(u)))
    elseif S.α==0
        x=Fun(identity,d)
        M=tocanonical(d,x)
        Mp=tocanonicalD(d,d.a)  
        u=-Mp*S.β*ff +(1-M).*differentiate(ff)
        Fun(u.coefficients,JacobiWeight(0.,S.β-1,space(u)))
    elseif S.β==0
        x=Fun(identity,d)
        M=tocanonical(d,x)
        Mp=tocanonicalD(d,d.a)  
        u=Mp*S.α*ff +(1+M).*differentiate(ff)
        Fun(u.coefficients,JacobiWeight(S.α-1,0.,space(u)))        
    else 
        x=Fun(identity,d)
        M=tocanonical(d,x)
        Mp=tocanonicalD(d,d.a) 
        u=(Mp*S.α)*(1-M).*ff- (Mp*S.β)*(1+M).*ff +(1-M.^2).*differentiate(ff)
        Fun(u.coefficients,JacobiWeight(S.α-1,S.β-1,space(u)))        
    end
end



function integrate{J<:JacobiWeight}(f::Fun{J})
    S=space(f)
    # we integrate by solving u'=f
    D=Derivative(S)
    if S.α==0 || S.β==0 
        D\f
    else
        s=sum(f)
        if isapprox(s,0.)
            D\f
        else
            # we normalized so it sums to zero, and so backslash works
            w=Fun(x->exp(-40x^2),81)
            w1=Fun(coefficients(w),S)
            w2=Fun(x->w1[x],domain(w1))
            c=s/sum(w1)
            v=f-w1*c      
            (c*integrate(w2))⊕(D\v)
        end   
    end
end

## Operators


function Derivative(S::JacobiWeight)
    d=domain(S)

    if S.α==S.β==0
        DerivativeWrapper(SpaceOperator(Derivative(S.space),S,JacobiWeight(0.,0.,rangespace(Derivative(S.space)))),1)
    elseif S.α==0
        x=Fun(identity,d)
        M=tocanonical(d,x)
        Mp=isa(d,Interval)?tocanonicalD(d,d.a):Fun(tocanonicalD(d,x),S.space) #TODO hack for Ray, which returns JacobiWeight but doesn't need to
        DD=(-Mp*S.β) +(1-M)*Derivative(S.space)
        DerivativeWrapper(SpaceOperator(DD,S,JacobiWeight(0.,S.β-1,rangespace(DD))),1)
    elseif S.β==0
        x=Fun(identity,d)
        M=tocanonical(d,x)
        Mp=isa(d,Interval)?tocanonicalD(d,d.a):Fun(tocanonicalD(d,x),S.space) #TODO hack for Ray, which returns JacobiWeight but doesn't need to
        DD=(Mp*S.α) +(1+M)*Derivative(S.space)
        DerivativeWrapper(SpaceOperator(DD,S,JacobiWeight(S.α-1,0.,rangespace(DD))),1)
    else 
        x=Fun(identity,d)
        M=tocanonical(d,x)
        Mp=isa(d,Interval)?tocanonicalD(d,d.a):Fun(tocanonicalD(d,x),S.space) #TODO hack for Ray, which returns JacobiWeight but doesn't need to
        DD=(Mp*S.α)*(1-M) - (Mp*S.β)*(1+M) +(1-M.^2)*Derivative(S.space)
        DerivativeWrapper(SpaceOperator(DD,S,JacobiWeight(S.α-1,S.β-1,rangespace(DD))),1)
    end

end

function Derivative(S::JacobiWeight,k::Integer)
    if k==1
        Derivative(S)
    else
        D=Derivative(S)
        DerivativeWrapper(TimesOperator(Derivative(rangespace(D),k-1).op,D.op),k)
    end
end




## Multiplication

#Left multiplication. Here, S is considered the domainspace and we determine rangespace accordingly.

function Multiplication{D<:JacobiWeight,T}(f::Fun{D,T},S::JacobiWeight)
    M=Multiplication(Fun(f.coefficients,space(f).space),S.space)
    rsp=canonicalspace(JacobiWeight(space(f).α+S.α,space(f).β+S.β,rangespace(M)))
    MultiplicationWrapper(f,SpaceOperator(M,S,rsp))
end

function Multiplication{D,T}(f::Fun{D,T},S::JacobiWeight)
    M=Multiplication(f,S.space)
    rsp=JacobiWeight(S.α,S.β,rangespace(M))
    MultiplicationWrapper(f,SpaceOperator(M,S,rsp))
end

function Multiplication{D<:JacobiWeight,T}(f::Fun{D,T},S::IntervalSpace)
    M=Multiplication(Fun(f.coefficients,space(f).space),S)
    rsp=JacobiWeight(space(f).α,space(f).β,rangespace(M))
    MultiplicationWrapper(f,SpaceOperator(M,S,rsp))
end

#Right multiplication. Here, S is considered the rangespace and we determine domainspace accordingly.

function Multiplication{D<:JacobiWeight,T}(S::JacobiWeight,f::Fun{D,T})
    M=Multiplication(Fun(f.coefficients,space(f).space),S.space)
    dsp=canonicalspace(JacobiWeight(S.α-space(f).α,S.β-space(f).β,domain(f)))
    MultiplicationWrapper(f,SpaceOperator(M,dsp,S))
end

function Multiplication{D,T}(S::JacobiWeight,f::Fun{D,T})
    M=Multiplication(f,S.space)
    dsp=JacobiWeight(S.α,S.β,domain(f))
    MultiplicationWrapper(f,SpaceOperator(M,dsp,S))
end

function Multiplication{D<:JacobiWeight,T}(S::IntervalSpace,f::Fun{D,T})
    M=Multiplication(Fun(f.coefficients,space(f).space),S)
    dsp=JacobiWeight(-space(f).α,-space(f).β,rangespace(M))
    MultiplicationWrapper(f,SpaceOperator(M,dsp,S))
end

## Conversion

maxspace(A::JacobiWeight,B::JacobiWeight)=JacobiWeight(min(A.α,B.α),min(A.β,B.β),maxspace(A.space,B.space))
minspace(A::JacobiWeight,B::JacobiWeight)=JacobiWeight(max(A.α,B.α),max(A.β,B.β),minspace(A.space,B.space))
maxspace(A::IntervalSpace,B::JacobiWeight)=maxspace(JacobiWeight(0.,0.,A),B)
maxspace(A::JacobiWeight,B::IntervalSpace)=maxspace(A,JacobiWeight(0.,0.,B))

isapproxinteger(x)=isapprox(x,int(x))



function Conversion(A::JacobiWeight,B::JacobiWeight)
    @assert isapproxinteger(A.α-B.α) && isapproxinteger(A.β-B.β)
    
    if A.space==B.space
        d=domain(A)        
        x=Fun(identity,d)
        M=tocanonical(d,x)
        m=(1+M).^int(A.α-B.α).*(1-M).^int(A.β-B.β)
        SpaceOperator(Multiplication(m,B.space),A,B)# Wrap the operator with the correct spaces
    elseif isapprox(A.α,B.α) && isapprox(A.β,B.β)
        SpaceOperator(Conversion(A.space,B.space),A,B)
    else
        d=domain(A)        
        x=Fun(identity,d)
        M=tocanonical(d,x)    
        C=Conversion(A.space,B.space)
        m=(1+M).^int(A.α-B.α).*(1-M).^int(A.β-B.β)
        SpaceOperator(Multiplication(m,B.space)*C,A,B)
    end        
end


isapproxleq(a,b)=(a<=b || isapprox(a,b))
# return the space that has banded Conversion to the other, or NoSpace
function conversion_rule(A::JacobiWeight,B::JacobiWeight)
    if isapproxinteger(A.α-B.α) && isapproxinteger(A.β-B.β)    
        ct=conversion_type(A.space,B.space)
        if ct == B.space && isapproxleq(A.α,B.α) && isapproxleq(A.β,B.β)
            return B
        elseif ct == A.space && isapproxleq(B.α,A.α) && isapproxleq(B.β,A.β)
            return A
        end
    end

    return NoSpace()
end


## Evaluation

function  Base.getindex{J<:JacobiWeight}(op::Evaluation{J,Bool},kr::Range)
    S=op.space
    @assert op.order<=1
    d=domain(op)

    if op.x
        @assert S.β>=0
        if S.β==0
            if op.order==0
                2^S.α*getindex(Evaluation(S.space,op.x),kr)
            else #op.order ===1
                @assert isa(d,Interval)            
                2^S.α*getindex(Evaluation(S.space,op.x,1),kr)+(tocanonicalD(d,d.a)*S.α*2^(S.α-1))*getindex(Evaluation(S.space,op.x),kr)
            end
        else
            @assert op.order==0
            zeros(kr)
        end
    else
        @assert S.α>=0
        if S.α==0
            if op.order==0
                2^S.β*getindex(Evaluation(S.space,op.x),kr)
            else #op.order ===1
                @assert isa(d,Interval)            
                2^S.β*getindex(Evaluation(S.space,op.x,1),kr)-(tocanonicalD(d,d.a)*S.β*2^(S.β-1))*getindex(Evaluation(S.space,op.x),kr)
            end
        else
            @assert op.order==0        
            zeros(kr)
        end    
    end
end


## Σ

#function Base.getindex{T,λ}(S::Σ{T,JacobiWeight{Ultraspherical{λ}},Ultraspherical{λ}},f::Fun{JacobiWeight{Ultraspherical{λ}},T})
#
#    @assert domain(f) == domain(S)
#    dsp,rsp = domainspace(S),rangespace(S)
#    sp = space(f)
#    newdomainspace = canonicalspace(JacobiWeight(λ-.5-sp.α,λ-.5-sp.β,domain(S)))
#    
#    SpaceOperator(S*Multiplication(f,newdomainspace),newdomainspace,rsp)
#end

function addentries!{T,λ}(S::Σ{T,JacobiWeight{Ultraspherical{λ}},Ultraspherical{λ}},A,kr::Range)
    dsp,rsp = domainspace(S),rangespace(S)
    d = domain(S)
    @assert isa(d,Interval)
    @assert dsp.α==dsp.β==λ-0.5
    
    C = .5(d.b-d.a)
    for k=kr
        k == 1? A[k,k] += C*gamma(λ+one(T)/2)*gamma(one(T)/2)/gamma(λ+one(T)) : A[k,k] += zero(T)
    end
    
    A
end