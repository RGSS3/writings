## Introduction to the backwards operator

### Fibonacci Recursion

Imagine you'll to implement the classic fibonacci number:
#### Code 1
```prolog
fib(0, 1).
fib(1, 1).
fib(N, A) :-
  N1 is N - 1,
  N2 is N - 2,
  fib(N1, A1),
  fib(N2, A2),
  A is A1 + A2
  /* ,writeln((N, A)) */
  .
```

This looks good, but if you remove the comment characters around `writeln`, you'll find even simple `fib(13, A)` took many redundant calculations.

One of the optimization is to iterate rather than bare recursion.
#### Code 2
```prolog
fib(0, _, A, A).
fib(N, A, B, Ans) :-
  N > 0,
  C is B,
  D is A + B,
  N1 is N - 1,
  fib(N1, C, D, Ans).

fib(N, A) :-
    fib(N, 0, 1, A).
```

`fib(13, Ans)` only took ~13 times.

Or you can use some dirty state in `Code 1`:
#### Code 3
```prolog
:- dynamic fib/2.
fib(0, 1).
fib(1, 1).
fib(N, A) :-
  N1 is N - 1,
  N2 is N - 2,
  fib(N1, A1),
  fib(N2, A2),
  A is A1 + A2,
  writeln((N, A)), 
  asserta((fib(N, A) :- !)).  % asserta means to insert this before all fib(_, _) clauses, ! will cut the backtracking.
```

`Code 3` slightly optimizes without many modifications to `Code 1`
### Pouring Water problem
Imagine you have 3 jugs with volume 10/7/3,     
Only Jug 10 is full, the other two are empty.    
Split the water to equal half 5/5.    
More can be found at
[http://mathcentral.uregina.ca/QQ/database/QQ.09.98/lane1.html](http://mathcentral.uregina.ca/QQ/database/QQ.09.98/lane1.html).


First we define the `pouring`:
```prolog
% The possible operation
pour(AMax-A, BMax-B, AMax-AA, BMax-BB, C, C) :-
   Total is A + B,
   BB is min(Total, BMax),
   AA is Total - BB,
   AA \= A.

try_pour((A, B, C), (A1, B1, C1)) :-
    pour(A1, B1, A, B, C, C1);
    pour(A1, C1, A, C, B, B1);
    pour(B1, C1, B, C, A, A1);
    pour(B1, A1, B, A, C, C1);
    pour(C1, A1, C, A, B, B1);
    pour(C1, B1, C, B, A, A1).
```

Then we define some functors and goal:
```prolog
:-dynamic parent/2.    % what node does this node come from?
:-dynamic cost/2.      % how long is the node from initial node

init((10-10, 7-0, 3-0)).
final((10-5, 7-5, 3-0)).
```

```prolog
% one step is to 
% 1. choose an exisiting state = A
% 2. get its cost = X
% 3. expand a new state = B
% 4. if we can update cost(B, Z), update it

step :-
  state(A),            
  cost(A, X),
  try_pour(B, A),
  ((cost(B, Y), Y > X + 1; \+cost(B, _)) ->
       Z is X + 1,
       retractall(cost(B, _)),
       retractall(parent(B, _)),
       assert(cost(B, Z)),
       assert(parent(B, A))).
       
run:-
  init(A),
  abolish(cost/2),
  abolish(parent/2),
  assert(cost(A, 0)),
  repeat,
    (step -> fail;  % repeat step until no more nodes to expand
      !,
      final(B),
      printpath(B)).
      
printpath(B) :-
  (parent(B, A) -> printpath(A), !; true), writeln(B).
```



### Existential Arrow
By `Existential` there are many meanings.      
Here we define this term as several different form:

1. A prolog fact or predicate without clauses.
```prolog
fib(0, 1). % fact
1 is 4 - 3. % predicate evaluation
```

2. 
A prolog clause with body, either not recursive or deterministically recursive.

```prolog
succ(A, B) :- B is A + 1.  % not recursive

len([], 0).
len([_|Xs], A) :- A is 1 + Xs. % non-deterministic

%but if:
detlen(A, B) :- 
  ground(A),   % ensure A is ground
  len(A, B).   % detlen is deterministic
``` 

3.
A witness functor like:    
```prolog
  A = [fib(0, 1), fib(1, 1)],
  member(fib(0, N), A).
```

We say the functor ```fib(0, 1)``` is the witness and `N` will be unified to 1
