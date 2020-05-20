## Creating a monad and donation in prolog is easy!

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

do((A, C), B) :-
  A =.. ['is'|_], !,
  call(A),
  do(C, B).

do((A, C), B) :-
  \+(A =.. ['<-'|_]), !,
  call(A, _),
  do(C, B).
      

      
do((A, C), B) :-
  A =.. ['<-', LHS, RHS],
  bind(RHS, [LHS, B1]>>do(C, B1), B).
      
double(X, YY) :- Y is X * 2, YY := return(Y).
```
