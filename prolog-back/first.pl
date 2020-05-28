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
