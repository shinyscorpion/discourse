defmodule Discourse.SSO do
  @moduledoc """
  kDiscourse SSO.

  Reference: https://meta.discourse.org/t/official-single-sign-on-for-discourse-sso/13045
  """
  require Logger

  @string_fields ~w(
    avatar_url
    bio
    card_background_url
    email
    external_id
    locale
    name
    nonce
    profile_background_url
    return_sso_url
    title
    username
    website
  )a

  @boolean_fields ~w(
    admin
    avatar_force_update
    locale_force_update
    moderator
    require_activation
    suppress_welcome_message
  )a

  @list_fields ~w(
    add_groups
    groups
    remove_groups
  )a

  @fields @string_fields ++ @boolean_fields ++ @list_fields

  @doc ~S"""
  Verify the passed sso nonce and signature.

  The `secret` set for Discourse is taken from the application configurations,
  but can also be supplied as option.

  The passed `secret` takes priority over the configured one.

  ## Example

  ```
  iex> SSO.validate("bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGI=\n", "2828aa29899722b35a2f191d34ef9b3ce695e0e6eeec47deb46d588d70c7cb56")
  {:ok, "cb68251eefb5211e58c00ff1395f0c0b"}
  ```
  """
  @spec validate(String.t(), String.t(), Keyword.t()) ::
          {:ok, nonce :: String.t()} | {:error, atom}
  def validate(sso, sig, opts \\ []) do
    with true <- sig(sso, opts) == sig,
         {:ok, decoded} <- Base.decode64(String.trim(sso, "\n"), padding: true),
         %{"nonce" => nonce} <- URI.decode_query(decoded) do
      {:ok, nonce}
    else
      :error -> {:error, :invalid_encoding}
      false -> {:error, :invalid_signature}
      _ -> {:error, :invalid_payload}
    end
  end

  @doc ~S"""
  Creates a signed url to redirect users to.

  The following user data is required:

    - `id`, the id of the user in your system.
    - `email`, the email of the user. (Assumed to be verified.)
    - `nonce`, the nonce given at the start of the request.

  For more options see: `sign/4`.

  ## URL

  The `url` set for Discourse is taken from the application configurations,
  but can also be supplied as option.

  The passed `url` takes priority over the configured one.

  ## Example

  ```
  iex> SSO.sign_url(323211321, "bob@example.com", "cb68251eefb5211e58c00ff1395f0c0b")
  "http://discuss.example.com?sig=4ba1737d622155848ddb9a22f6ccb61801cb1ad40544aef5304caa300655f6b2&sso=bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGImZW1haWw9Ym9iJTQwZXhhbXBsZS5jb20mZXh0ZXJuYWxfaWQ9MzIzMjExMzIx"
  ```
  """
  @spec sign_url(String.t(), String.t(), String.t(), Keyword.t()) :: String.t()
  def sign_url(id, email, nonce, opts \\ []) do
    opts
    |> url()
    |> URI.merge(%URI{query: URI.encode_query(sign(id, email, nonce, opts))})
    |> to_string
  end

  @doc ~S"""
  Sign the nonce and user data.

  The following user data is required:

    - `id`, the id of the user in your system.
    - `email`, the email of the user. (Assumed to be verified.)
    - `nonce`, the nonce given at the start of the request.

  ## Secret

  The `secret` set for Discourse is taken from the application configurations,
  but can also be supplied as option.

  The passed `secret` takes priority over the configured one.

  ## Options

  The following extra user data can be given:

    - `username`, the user's [preferred] username.
    - `name`, the user's [real] name.

  ## Flags (boolean)

    - `admin`, set the user as admin.
    - `avatar_force_update`, force avatar update.
    - `locale_force_update`, force locale update.
    - `moderator`, set the user as moderator.
    - `require_activation`, require email verification.
    - `suppress_welcome_message`, suppress Discourse welcome message.

  ## Example

  ```
  iex> SSO.sign(323211321, "bob@example.com", "cb68251eefb5211e58c00ff1395f0c0b")
  %{
    sig: "4ba1737d622155848ddb9a22f6ccb61801cb1ad40544aef5304caa300655f6b2",
    sso: "bm9uY2U9Y2I2ODI1MWVlZmI1MjExZTU4YzAwZmYxMzk1ZjBjMGImZW1haWw9Ym9iJTQwZXhhbXBsZS5jb20mZXh0ZXJuYWxfaWQ9MzIzMjExMzIx"
  }
  ```
  """
  @spec sign(integer | String.t(), String.t(), String.t(), Keyword.t()) :: %{
          sso: String.t(),
          sig: String.t()
        }
  def sign(id, email, nonce, opts \\ []) do
    payload =
      opts
      |> Keyword.put(:external_id, id)
      |> Keyword.put(:email, email)
      |> Keyword.put(:nonce, nonce)
      |> Keyword.take(@fields)
      |> Enum.map(&encode_field/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.join("&")
      |> Base.encode64(padding: true)

    %{
      sso: payload,
      sig: sig(payload, opts)
    }
  end

  ### Helpers ###

  @spec encode_field({atom, any}) :: String.t() | nil
  defp encode_field({field, list}) when field in @list_fields and list != [],
    do: "#{field}=#{URI.encode_www_form(Enum.join(list, ","))}"

  defp encode_field({field, value}) when field in @string_fields,
    do: "#{field}=#{URI.encode_www_form(to_string(value))}"

  defp encode_field({field, value}) when field in @boolean_fields and is_boolean(value) do
    if value === true, do: "#{field}=true"
  end

  defp encode_field({field, _}) when field in @fields do
    Logger.warn(fn -> "Discourse SSO: Invalid value for: #{field}" end)
  end

  @spec sig(binary, Keyword.t()) :: String.t()
  defp sig(payload, opts),
    do:
      :sha256
      |> :crypto.hmac(secret(opts), payload)
      |> Base.encode16(case: :lower)

  ### Config ###

  @spec secret(Keyword.t()) :: String.t()
  defp secret(opts),
    do: config(:secret, opts, "Discourse SSO: Need to set `secret` in config or opts.")

  @doc false
  @spec url(Keyword.t()) :: String.t()
  def url(opts), do: config(:url, opts, "Discourse SSO: Need to set `url` in config or opts.")

  @spec config(atom, Keyword.t(), String.t()) :: String.t() | no_return
  defp config(field, opts, message) do
    Keyword.get_lazy(
      opts,
      field,
      fn -> Application.get_env(:discourse, field) || raise message end
    )
  end
end
