defmodule Medium.Guardian do
  use Guardian, otp_app: :medium

  alias Medium.Accounts

  def subject_for_token(%{id: id}, _claims) do
    # You can use any value for the subject of your token but
    # it should be useful in retrieving the resource later, see
    # how it being used on `resource_from_claims/1` function.
    # A unique `id` is a good subject, a non-unique email address
    # is a poor subject.
    sub = to_string(id)
    {:ok, sub}
  end
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end

  def resource_from_claims(%{"sub" => id}) do
    # Here we'll look up our resource from the claims, the subject can be
    # found in the `"sub"` key. In above `subject_for_token/2` we returned
    # the resource id so here we'll rely on that to look it up.
    case Accounts.get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok,  user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  def generate_tokens(user) do
    {:ok, access_token, _} = encode_and_sign(user, %{}, [token_type: "access", ttl: {30, :day}])

    # {:ok, access_token} = exchange_token(refresh_token)
    {:ok, access_token}
  end

  # defp exchange_token(refresh_token) do
  #   case exchange(refresh_token, "refresh", "access", ttl: {1, :day}) do
  #     {:ok, _refresh_token, {access_token, _access_token_claim}} ->
  #       {:ok, access_token}

  #     {:error, reason} ->
  #       {:error, reason}
  #   end
  # end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

end
