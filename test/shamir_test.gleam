import gleeunit
import gleeunit/should
import shamir

pub fn main() {
  gleeunit.main()
}

pub fn round_trip_test() {
  let secret =
    "testing123😊!!!&*😊aaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbb____"
  let share_res = shamir.share(secret, 5, 3)
  let assert Ok([share_1, _share_2, share_3, _share_4, share_5]) = share_res
  let assert Ok(combined) = shamir.combine([share_1, share_3, share_5])
  combined |> should.equal(secret)
}

pub fn new_share_test() {
  let secret =
    "testing123😊!!!&*😊aaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbb____"
  let share_res = shamir.share(secret, 5, 3)
  let assert Ok([share_1, _share_2, share_3, share_4, _share_5]) = share_res
  let assert Ok(share_new) = shamir.new_share(6, [share_1, share_3, share_4])
  let assert Ok(new_combined) = shamir.combine([share_1, share_4, share_new])
  new_combined |> should.equal(secret)
}
