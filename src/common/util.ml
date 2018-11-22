let (%) : 'a 'b 'c. ('b -> 'c) -> ('a -> 'b) -> 'a -> 'c = fun a b c -> a (b c)
let identity x = x
