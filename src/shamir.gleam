import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string

const max_shares = 0xff

const id_len = 2

fn exps_logs() {
  let kvs =
    list.range(0, max_shares + 1)
    |> list.map_fold(1, fn(x, i) {
      let x = case x * 2 {
        x if x > max_shares ->
          x |> int.bitwise_exclusive_or(29) |> int.bitwise_and(max_shares)
        x -> x
      }
      #(x, #(i, x))
    })
    |> pair.second
  #(dict.from_list(kvs), dict.from_list(list.map(kvs, pair.swap)))
}

fn do_hex_to_ints(
  data: String,
  acc: List(Int),
  first_half: Option(Int),
) -> Result(List(Int), Nil) {
  case first_half, data {
    None, "" -> Ok(list.reverse(acc))
    None, "0" <> rest -> do_hex_to_ints(rest, acc, Some(0))
    Some(x), "0" <> rest -> do_hex_to_ints(rest, [16 * x + 0, ..acc], None)
    None, "1" <> rest -> do_hex_to_ints(rest, acc, Some(1))
    Some(x), "1" <> rest -> do_hex_to_ints(rest, [16 * x + 1, ..acc], None)
    None, "2" <> rest -> do_hex_to_ints(rest, acc, Some(2))
    Some(x), "2" <> rest -> do_hex_to_ints(rest, [16 * x + 2, ..acc], None)
    None, "3" <> rest -> do_hex_to_ints(rest, acc, Some(3))
    Some(x), "3" <> rest -> do_hex_to_ints(rest, [16 * x + 3, ..acc], None)
    None, "4" <> rest -> do_hex_to_ints(rest, acc, Some(4))
    Some(x), "4" <> rest -> do_hex_to_ints(rest, [16 * x + 4, ..acc], None)
    None, "5" <> rest -> do_hex_to_ints(rest, acc, Some(5))
    Some(x), "5" <> rest -> do_hex_to_ints(rest, [16 * x + 5, ..acc], None)
    None, "6" <> rest -> do_hex_to_ints(rest, acc, Some(6))
    Some(x), "6" <> rest -> do_hex_to_ints(rest, [16 * x + 6, ..acc], None)
    None, "7" <> rest -> do_hex_to_ints(rest, acc, Some(7))
    Some(x), "7" <> rest -> do_hex_to_ints(rest, [16 * x + 7, ..acc], None)
    None, "8" <> rest -> do_hex_to_ints(rest, acc, Some(8))
    Some(x), "8" <> rest -> do_hex_to_ints(rest, [16 * x + 8, ..acc], None)
    None, "9" <> rest -> do_hex_to_ints(rest, acc, Some(9))
    Some(x), "9" <> rest -> do_hex_to_ints(rest, [16 * x + 9, ..acc], None)
    None, "A" <> rest -> do_hex_to_ints(rest, acc, Some(10))
    Some(x), "A" <> rest -> do_hex_to_ints(rest, [16 * x + 10, ..acc], None)
    None, "B" <> rest -> do_hex_to_ints(rest, acc, Some(11))
    Some(x), "B" <> rest -> do_hex_to_ints(rest, [16 * x + 11, ..acc], None)
    None, "C" <> rest -> do_hex_to_ints(rest, acc, Some(12))
    Some(x), "C" <> rest -> do_hex_to_ints(rest, [16 * x + 12, ..acc], None)
    None, "D" <> rest -> do_hex_to_ints(rest, acc, Some(13))
    Some(x), "D" <> rest -> do_hex_to_ints(rest, [16 * x + 13, ..acc], None)
    None, "E" <> rest -> do_hex_to_ints(rest, acc, Some(14))
    Some(x), "E" <> rest -> do_hex_to_ints(rest, [16 * x + 14, ..acc], None)
    None, "F" <> rest -> do_hex_to_ints(rest, acc, Some(15))
    Some(x), "F" <> rest -> do_hex_to_ints(rest, [16 * x + 15, ..acc], None)
    _, _ -> Error(Nil)
  }
}

fn hex_to_ints(data: String) -> Result(List(Int), Nil) {
  do_hex_to_ints(data, [], option.None)
}

fn do_ints_to_hex(data: List(Int), acc: String) -> String {
  case data {
    [] -> acc
    [x, ..xs] ->
      do_ints_to_hex(xs, acc <> string.pad_left(int.to_base16(x), 2, "0"))
  }
}

fn ints_to_hex(data: List(Int)) -> String {
  do_ints_to_hex(data, "")
}

fn do_ints_to_bit_array(data: List(Int), acc: BitArray) -> BitArray {
  case data {
    [] -> acc
    [x, ..rest] -> do_ints_to_bit_array(rest, <<acc:bits, x:8>>)
  }
}

fn ints_to_bit_array(data: List(Int)) -> BitArray {
  do_ints_to_bit_array(data, <<>>)
}

fn do_bit_array_to_ints(data: BitArray, acc: List(Int)) -> List(Int) {
  case data {
    <<x, rest:bytes>> -> do_bit_array_to_ints(rest, [x, ..acc])
    _ -> list.reverse(acc)
  }
}

fn bit_array_to_ints(data: BitArray) -> List(Int) {
  do_bit_array_to_ints(data, [])
}

pub type ShamirError {
  NotEnoughShares
  MalformedId
  IdOutOfRange
  DuplicateIds
  MalformedData
  MissingLookupValue
  InvalidStringValue
  InvalidShareNumber
  InvalidThreshold
  NotEnoughSharesForThreshold
  InvalidPadLength
}

fn combine_raw(shares: List(String), at: Int) -> Result(List(Int), ShamirError) {
  use <- bool.guard(list.length(shares) < 2, Error(NotEnoughShares))
  use xs <- result.try(
    list.try_map(shares, fn(share) {
      share |> string.slice(0, id_len) |> int.base_parse(16)
    })
    |> result.replace_error(MalformedId),
  )
  use <- bool.guard(
    list.any(xs, fn(id) { id < 1 || id > max_shares }),
    Error(IdOutOfRange),
  )
  use <- bool.guard(
    list.length(xs) > list.length(list.unique(xs)),
    Error(DuplicateIds),
  )
  use ws <- result.try(
    list.try_map(shares, fn(share) {
      share
      |> string.slice(id_len, string.length(share) - id_len)
      |> hex_to_ints
    })
    |> result.replace_error(MalformedData),
  )
  let #(exps, logs) = exps_logs()
  list.transpose(ws)
  |> list.try_map(fn(ys) {
    list.zip(xs, ys)
    |> list.try_fold(0, fn(sum, xy) {
      let #(xi, yi) = xy
      use <- bool.guard(yi == 0, Ok(sum))
      use pi <- result.try(
        dict.get(logs, yi) |> result.replace_error(MissingLookupValue),
      )
      use product <- result.try(
        list.try_fold(xs, pi, fn(product, xj) {
          use <- bool.guard(xi == xj || product == -1, Ok(product))
          use <- bool.guard(at == xj, Ok(-1))
          use la <- result.try(
            dict.get(logs, int.bitwise_exclusive_or(at, xj))
            |> result.replace_error(MissingLookupValue),
          )
          use lb <- result.try(
            dict.get(logs, int.bitwise_exclusive_or(xi, xj))
            |> result.replace_error(MissingLookupValue),
          )
          Ok({ product + la - lb + max_shares } % max_shares)
        }),
      )
      use <- bool.guard(product == -1, Ok(sum))
      use ep <- result.try(
        dict.get(exps, product)
        |> result.replace_error(MissingLookupValue),
      )
      Ok(int.bitwise_exclusive_or(sum, ep))
    })
  })
}

fn trim_data(data: List(Int)) -> List(Int) {
  case data {
    [] -> []
    [0, ..xs] -> trim_data(xs)
    [_, ..xs] -> list.reverse(xs)
  }
}

pub fn combine(shares: List(String)) -> Result(String, ShamirError) {
  use raw <- result.try(combine_raw(shares, 0))
  raw
  |> list.reverse
  |> trim_data
  |> ints_to_bit_array
  |> bit_array.to_string
  |> result.replace_error(InvalidStringValue)
}

pub fn share_with_pad_length(
  secret: String,
  num_shares: Int,
  threshold: Int,
  pad_length: Int,
) -> Result(List(String), ShamirError) {
  use <- bool.guard(
    num_shares < 2 || num_shares > max_shares,
    Error(InvalidShareNumber),
  )
  use <- bool.guard(
    threshold < 2 || threshold > max_shares,
    Error(InvalidThreshold),
  )
  use <- bool.guard(threshold > num_shares, Error(NotEnoughSharesForThreshold))
  use <- bool.guard(
    pad_length < 0 || pad_length > 1024,
    Error(InvalidPadLength),
  )
  let #(exps, logs) = exps_logs()
  use logs_slice <- result.try(
    list.range(1, num_shares)
    |> list.try_map(dict.get(logs, _))
    |> result.replace_error(MissingLookupValue),
  )
  let ints = bit_array.from_string(secret) |> bit_array_to_ints
  let ints_len = list.length(ints)
  case ints_len % pad_length {
    0 -> ints
    x ->
      list.append(ints, [255, ..list.repeat(0, { { pad_length - x - 1 } * 8 })])
  }
  |> list.try_map(fn(n) {
    let coeffs =
      list.reverse([
        n,
        ..bit_array_to_ints(crypto.strong_random_bytes(threshold - 1))
      ])
    list.try_map(logs_slice, fn(log) {
      list.try_fold(coeffs, 0, fn(fx, coeff) {
        use <- bool.guard(fx == 0, Ok(coeff))
        use lf <- result.try(
          dict.get(logs, fx) |> result.replace_error(MissingLookupValue),
        )
        use el <- result.try(
          dict.get(exps, { log + lf } % max_shares)
          |> result.replace_error(MissingLookupValue),
        )
        Ok(int.bitwise_exclusive_or(el, coeff))
      })
    })
  })
  |> result.map(list.transpose)
  |> result.map(list.index_map(_, fn(l, i) {
    string.pad_left(int.to_base16(i + 1), 2, "0") <> ints_to_hex(l)
  }))
}

pub fn share(
  secret: String,
  num_shares: Int,
  threshold: Int,
) -> Result(List(String), ShamirError) {
  share_with_pad_length(secret, num_shares, threshold, 128)
}

pub fn new_share(id: Int, shares: List(String)) -> Result(String, ShamirError) {
  use raw <- result.try(combine_raw(shares, id))
  Ok(string.pad_left(int.to_base16(id), 2, "0") <> ints_to_hex(raw))
}
