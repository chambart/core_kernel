open Std_internal
module Field = Fieldslib.Field

type 'a t =
  { mutable elts : 'a list;
    mutable length : int;
  }
with bin_io, fields, sexp_of

let sexp_of_t_internal = sexp_of_t
let sexp_of_t = `Rebound_later
let _ = sexp_of_t

let invariant a_invariant t : unit =
  try
    let check f field = f (Field.get field t) in
    Fields.iter
      ~elts:(check (fun elts -> List.iter elts ~f:a_invariant))
      ~length:(check (fun length -> assert (length = List.length t.elts)))
  with exn ->
    failwiths "Linked_stack.invariant failed" (exn, t) <:sexp_of< exn * _ t_internal >>
;;

let create () = { elts = []; length = 0; }

(* We always want to set elts and length at the same time.  Having a function to do so
   helps us to remember. *)
let set t elts length = t.elts <- elts; t.length <- length

let push t x = set t (x :: t.elts) (t.length + 1)

let pop_error = Error.of_string "Stack.pop of empty stack"

let pop_exn t =
  match t.elts with
  | [] -> Error.raise pop_error
  | x :: l -> set t l (t.length - 1); x
;;

let pop t =
  match t.elts with
  | [] -> None
  | x :: l -> set t l (t.length - 1); Some x
;;

let top_error = Error.of_string "Stack.top of empty stack"

let top_exn t =
  match t.elts with
  | [] -> Error.raise top_error
  | x :: _ -> x
;;

let top t =
  match t.elts with
  | [] -> None
  | x :: _ -> Some x
;;

let clear t = set t [] 0

let copy t = { elts = t.elts; length = t.length; }

let length t = t.length

let is_empty t = t.length = 0

let iter t ~f = List.iter t.elts ~f

let fold t ~init ~f = List.fold t.elts ~init ~f

let count t ~f = List.count t.elts ~f
let sum m t ~f = List.sum m t.elts ~f
let min_elt t ~cmp = List.min_elt t.elts ~cmp
let max_elt t ~cmp = List.max_elt t.elts ~cmp

let exists t ~f = List.exists t.elts ~f

let mem ?equal t a = List.mem ?equal t.elts a

let for_all t ~f = List.for_all t.elts ~f

let find t ~f = List.find t.elts ~f

let find_map t ~f = List.find_map t.elts ~f

let to_list t = t.elts

let of_list l = { elts = l; length = List.length l }

let to_array t = Array.of_list t.elts

let sexp_of_t sexp_of_a t = Sexplib.Conv.sexp_of_list sexp_of_a (to_list t)

let t_of_sexp a_of_sexp sexp =
  let elts = Sexplib.Conv.list_of_sexp a_of_sexp sexp in
  { elts = elts; length = List.length elts; }
;;

let until_empty t f =
  let rec loop () = if t.length > 0 then (f (pop_exn t); loop ()) in
  loop ()
;;
