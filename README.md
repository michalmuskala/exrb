# Exrb

Ruby-Elixir interoperability

There are some gems for decoding Erlang's External Term Format, but they were
all prepared for Erlang and it's semantics. This library keeps itself closer to
Elixir:

Ruby  |  Elixir
----- | -------
`Fixnum` | `integer`
`Bignum` | `integer`
`Float`  | `float`
`Symbol` | `atom`
`Exrb::NewReference` or `Exrb::Reference` | `reference`
`Exrb::Port` | `port`
`Exrb::Pid` | `pid`
`Exrb::Tuple` | `tuple`
`Hash` | `map`
`Exrb::ErlangNil` | `[]`
`Array` | `list|char_list`
`Exrb::ImproperList` | `improper_list`
utf-8 encoded `String` | `String.t`
`Exrb::Binary` | `binary` that is not valid utf-8
`Exrb::Function` or `Exrb::NewFunction` | `fun`
`Exrb::Export` | `fun` as in `&String.is_string?/1`
`Exrb::Bitstring` | `bitstring`

Currently a lot of those types is related to the External Term Format, but they
will be merged together in the future for uniform representation.

All custom type classes in Ruby are deep frozen.
