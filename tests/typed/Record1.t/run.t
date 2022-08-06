  $ dune build
  $ zanuda -dir .
  File "Record1.ml", line 4, characters 11-34:
  4 | let f2 r = { x=r.x; y=r.y; z=r.z }
                 ^^^^^^^^^^^^^^^^^^^^^^^
  Alert zanuda-linter: Rewrite record as 'r'
  File "Record1.ml", line 5, characters 11-33:
  5 | let f3 r = { x=r.x; y=r.y; z=18 }
                 ^^^^^^^^^^^^^^^^^^^^^^
  Alert zanuda-linter: Rewrite record as '{ r with z = 18 }'
  File "Record1.ml", line 6, characters 14-38:
  6 | let f4 r r2 = { x=r.x; y=r.y; z=r2.z }
                    ^^^^^^^^^^^^^^^^^^^^^^^^
  Alert zanuda-linter: Rewrite record as '{ r with z = (r2.z) }'
  File "Record1.ml", line 7, characters 14-36:
  7 | let f5 r r2 = { x=r.x; y=1; z=r2.z }
                    ^^^^^^^^^^^^^^^^^^^^^^
  Alert zanuda-linter: Rewrite record as '{ r with z = (r2.z); y = 1 }'
