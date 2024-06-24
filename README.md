# shamir

[![Package Version](https://img.shields.io/hexpm/v/shamir)](https://hex.pm/packages/shamir)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/shamir/)

```sh
gleam add shamir
```
```gleam
import shamir

pub fn main() {
  let secret = "testing123!"
  io.println("Original: " <> data)
  let share_res = shamir.share(data, 5, 3)
  let assert Ok([share_1, share_2, share_3, share_4, share_5]) = share_res
  io.println("Share 1: " <> share_1)
  io.println("Share 2: " <> share_2)
  io.println("Share 3: " <> share_3)
  io.println("Share 4: " <> share_4)
  io.println("Share 5: " <> share_5)
  let assert Ok(combined) = shamir.combine([share_1, share_3, share_5])
  io.println("Combined Shares: " <> combined)
  let assert Ok(share_new) = shamir.new_share(6, [share_1, share_3, share_4])
  io.println("New Share: " <> share_new)
  let assert Ok(new_combined) = shamir.combine([share_1, share_4, share_new])
  io.println("Combined New Shares: " <> new_combined)
}
```

Further documentation can be found at <https://hexdocs.pm/shamir>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
