## Creating a monad and do-notation in prolog is easy!
Prolog isn't limiting its capability in logic and backtracking by exposing directly access to AST(and operators).  
This is how I used to imitate Haskell.

DSL looks like:
```prolog
36 ?- B := do
   X <- [1,2,3],
   Y <- [3,4,5],
   Z is X * Y,
   return(Z).
B = [3, 4, 5, 6, 8, 10, 9, 12, 15] ;
false.
```

What's implemented(and what's wanted if you want to try from scratch):
   * some known monad (by defining return/bind)
   * do
     * do is a prefix operator with somehow lower precedence.
     * define an operator <- and pattern-match it
     * lambda is useful([https://www.swi-prolog.org/pldoc/man?section=yall])


```prolog
:- op(1030, xfx, :=).
:- op(1020, fx, do).
:- op(990, xfx, <-).

:- discontiguous return/2.
:- discontiguous bind/3.

checkedcall(T, F, A, B) :-
  call(F, A, B),
  B =.. [T|_].

return(A, id(A)).
bind(id(A), F, B) :- checkedcall(id, F, A, B). 
A := B :- call(B, A).

return(A, [A]).
bind([], _, []).
bind([X|Xs], F, Y) :-
  maplist(checkedcall('[|]', F), [X|Xs], Ys), 
  append(Ys, Y).

return(A, just(A)).
bind(nothing, _, nothing).
bind(just(A), F, Y) :- checkedcall(just, F, A, Y), !;
                       checkedcall(nothing, F, A, Y).

return(A, right(A)).
bind(left(A), _, left(A)).
bind(right(A), F, Y) :- checkedcall(left, F, A, Y), !;
                        checkedcall(right, F, A, Y).
                            

do(A, B) :-
  \+(A =.. [','|_]),
  (A =.. [return|_] -> call(A, B); B = A).

do((A is D, C), B) :-
  A is D, !,
  do(C, B).

do((A, C), B) :-
  \+(A =.. ['<-'|_]), !,
  call(A, _),
  do(C, B).

do((LHS <- RHS, C), B) :-
  bind(RHS, [LHS, B1]>>do(C, B1), B).
      
double(X, YY) :- Y is X * 2, YY := return(Y).
```
