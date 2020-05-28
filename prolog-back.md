## Introduction to the existential arrow

### Fibonacci Recursion

Imagine you'd like to implement the classic fibonacci number:
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

This looks good, but if you remove the comment characters around `writeln`, you'll find even simple `fib(13, A)` takes many redundant calculations.

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
  % 1. fetch two known fib
  N1 is N - 1,
  N2 is N - 2,
  fib(N1, A1),
  fib(N2, A2),
  % 2. calculate the new one
  A is A1 + A2,
  writeln((N, A)), 
  % 3. update database
  asserta((fib(N, A) :- !)).  % asserta means to insert this before all fib(_, _) clauses, ! will cut the backtracking.
```

`Code 3` slightly optimizes without many modifications to `Code 1`



### Pouring Water problem
Imagine you have 3 jugs with volume 10/7/3,     
Only Jug 10 is full, the other two are empty.    
Split the water to equal half 5/5.    
More can be found at
[http://mathcentral.uregina.ca/QQ/database/QQ.09.98/lane1.html](http://mathcentral.uregina.ca/QQ/database/QQ.09.98/lane1.html).


### Code 4
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
% 3. expand to new states, each = B
% 4. if we can update cost(B, Z), update it

step :-
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

Here we no longer write something like `Code 3`.   
For example, you may wish to use a goal like `cost(A, X).`   
Then how to deal with `cost(state1, 6) -> cost(state2, 5) -> cost(state1, 4)`?     
This can indeed solve this problem too, however, by enumerating X from 0, 1, 2 ... .                 
But our `run` goal should do the enumeration(something Turing-recognizable?).

### Existential Arrow
By `Existential` there are many meanings. For example existential types in some languages.   
The last chapter is mainly about a normal BFS(breadth first search).   
Let's review the predicate `step` in the last chapter.    
It just do something like.   

 1. fetch some exisiting information  (cost(A, X))
 2. do some transformation and calculation (try_pour, calculating cost)
 3. adjust some information (retract/assert)
 
This gives us a sense: 
``` Existing -> New ```

And the predicate `run` just do some initialization and finalization work.   
Between them there is a repeatition of running `step` until no more info is generated.
The same applies to the code in the first chapter, taking some known fib(U, V)'s and generating
a new one.   

Let's take this pattern out and defining new operators.

### First Version
```prolog
:-op(1110, xfx, ~>).
run :- repeat, (step -> fail; !).
step :-
  (A ~> B),
  A,
  B.
```

Since `->` is already a well-known operator, we define this as `~>`   
`run` is direct. repeat `step`.   
`step` is simple too, match all clauses like `A~>B` then match A then do B.    

This is simple but also the way prolog works.

now let's just define another predicate `update(A, B)` to retract all A and then assert B.
```prolog
update(A, B) :-
  retractall(A),
  assert(B).
```

Then the step rule and main routine is:
```prolog
cost(A, X), 
try_pour(B, A),
(cost(B, Y), Y > X + 1; \+cost(B, Y))
~> 
   Z is X + 1,
   update(cost(B, _), cost(B, Z)),
   update(parent(B, _), parent(B, A)).

main :-
  init(I),
  abolish(cost/2),
  abolish(parent/1),
  assert(cost(I, 0)),
  run,
  final(F),
  printpath(F).
```

Other things are not changed.
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
:-dynamic parent/2.
:-dynamic cost/2.
% init state
init((10-10, 7-0, 3-0)).
final((10-5, 7-5, 3-0)).

:-op(1110, xfx, ~>).
run :- repeat, (step -> fail; !).
step :-
  (A ~> B),
  A,
  B.

update(A, B) :-
  retractall(A),
  assert(B).

cost(A, X), 
try_pour(B, A),
(cost(B, Y), Y > X + 1;
 \+cost(B, Y))
~> 
   Z is X + 1,
   update(cost(B, _), cost(B, Z)),
   update(parent(B, _), parent(B, A)).


main :-
  init(I),
  abolish(cost/2),
  abolish(parent/1),
  assert(cost(I, 0)),
  run,
  final(F),
  printpath(F).

printpath(B) :-
  (parent(B, A) -> printpath(A), !; true), writeln(B).

```

