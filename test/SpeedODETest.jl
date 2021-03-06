using ApproxFun, Base.Test
    import ApproxFun: A_ldiv_B_coefficients

## ODEs

d=Interval(-20000.,20000.)
x=Fun(identity,d)
u=[dirichlet(d);Derivative(d)^2+I]\[1,0,0]
u=[dirichlet(d);Derivative(d)^2+I]\[1,0,0]
@time u=[dirichlet(d);Derivative(d)^2+I]\[1,0,0]
println("Cos/Sin: should be ~0.017")


d=Interval(-1000.,5.)
x=Fun(identity,d)
u=[dirichlet(d);Derivative(d)^2-x]\[1,0,0]
u=[dirichlet(d);Derivative(d)^2-x]\[1,0,0]
@time u=[dirichlet(d);Derivative(d)^2-x]\[1,0,0]
println("Airy: 0.014356 seconds (1.08 k allocations: 8.015 MB)")

M=cache(ApproxFun.InterlaceOperator([dirichlet(d);Derivative(d)^2-x]);padding=true)
@time ApproxFun.resizedata!(M,12500,:)
println("Airy construct op: 0.005417 seconds (81 allocations: 5.279 MB)")



S=Chebyshev()
x=Fun(identity,S)
D=Derivative(S)
L=D^2+(7+2x+6x^2)
B=dirichlet(S)
n=20000
rhs=ones(n+2)
u=A_ldiv_B_coefficients([B;L],rhs)
u=A_ldiv_B_coefficients([B;L],rhs)
@time u=A_ldiv_B_coefficients([B;L],rhs)
println("Poly: should be ~0.025")


S=Chebyshev()
x=Fun(identity,S)
D=Derivative(S)
L=D^2+cos(x)
B=dirichlet(S)
n=2000
rhs=ones(n+2)
u=A_ldiv_B_coefficients([B;L],rhs;maxlength=Inf)
u=A_ldiv_B_coefficients([B;L],rhs;maxlength=Inf)
@time u=A_ldiv_B_coefficients([B;L],rhs;maxlength=Inf)
println("Cos: should be ~0.0075")

S=Chebyshev()
x=Fun(identity,S)
D=Derivative(S)
L=D^2+sin(x)
B=dirichlet(S)
n=2000
rhs=ones(n+2)
u=A_ldiv_B_coefficients([B;L],rhs;maxlength=Inf)
u=A_ldiv_B_coefficients([B;L],rhs;maxlength=Inf)
@time u=A_ldiv_B_coefficients([B;L],rhs;maxlength=Inf)
println("Sin: should be ~0.008663 seconds (660 allocations: 2.987 MB)")


## Piecewise
x=Fun(identity,Domain(-20..15) \ [-10.,-5.,0.,1.])
sp=space(x)
D=Derivative(sp)
B=dirichlet(sp)
u=[B;
    D^2-x]\Any[[airyai(-20.);zeros(size(B,1)-1)],0];
@time u=[dirichlet(sp);
    D^2-x]\Any[[airyai(-20.);zeros(size(B,1)-1)],0]


println("Piecewise Airy: should be ~0.008")


## Vector
d=Interval()
D=Derivative(d);
B=ldirichlet();
Bn=lneumann();

f=Fun(x->[exp(x),cos(x)],d)

A=[B 0;
   Bn 0;
   0 B;
   D^2-I 2.0I;
   0 D+I];

u=A\Any[0.,0.,0.,f...]
@time u=A\Any[0.,0.,0.,f...]
println("Systems: should be ~0.0008")


d=Interval(-300.,5.)
x=Fun(identity,d)
A=Derivative(d)^2-x
u=nullspace(A)
@test_approx_eq A[1:10,1:10] (A.')[1:10,1:10].'
@time u=nullspace(A)
println("Nullspace Airy: 0.052730 seconds (75.21 k allocations: 56.736 MB)")
