defmodule Discourse.SSOTest do
  use ExUnit.Case
  alias Discourse.SSO
  doctest SSO

  @id 173_278
  @email "bob@example.com"
  @nonce "cb68251eefb5211e58c00ff1395f0c0b"

  describe "validate/1" do
    test "error on invalid signature" do
      assert SSO.validate(
               "bad",
               "bad"
             ) == {:error, :invalid_signature}
    end

    test "error on invalid encoding" do
      assert SSO.validate(
               "bad",
               "72e037cf8c614ea7882e7b027b19e210b12da397fda049b053339903bffcadf5"
             ) == {:error, :invalid_encoding}
    end

    test "error on invalid payload" do
      assert SSO.validate(
               Base.encode64("bad", padding: false),
               "dbf8e17afd00811df1548f84c0a7de78509f53d83ffb30bc33434b4092e87afa"
             ) == {:error, :invalid_payload}
    end
  end

  defp sign(opts) do
    %{sso: sso, sig: _sig} = SSO.sign(@id, @email, @nonce, opts)

    sso
    |> Base.decode64!(padding: true)
    |> URI.decode_query()
  end

  describe "sign/4" do
    test "supports boolean flags" do
      assert sign(admin: true)["admin"] == "true"
      refute sign(admin: false)["admin"]
      refute sign(admin: 5)["admin"]
    end

    test "supports list flags" do
      assert sign(add_groups: ~W(a b))["add_groups"] == "a,b"
      refute sign(add_groups: [])["add_groups"]
    end

    test "discards unknown fields" do
      refute sign(fake: "so-fake")["fake"]
    end
  end
end
