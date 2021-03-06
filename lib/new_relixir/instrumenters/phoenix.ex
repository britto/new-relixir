defmodule NewRelixir.Instrumenters.Phoenix do
  @moduledoc """
  New Relic instrumenter for Phoenix controllers.

  It relies on the instrumentation API provided by `Phoenix.Endpoint`. To set it up,
  include this module in the list of `instrumenters` of your Endpoint config:

      config :my_app, MyAppWeb.Endpoint,
        instrumenters: [NewRelixir.Instrumenters.Phoenix],

  Transaction traces will be composed of both controller and action names, e.g.
  `/HomeController#index`, `/ProfileController#update`.
  """

  alias NewRelixir.{CurrentTransaction, Transaction, Utils}

  @doc """
  If first argument is the atom `:start` this is used as the Start callback for
  Phoenix controllers. Phoenix calls it once a request is routed, before
  processing a controller action.
  Returns the transaction name, formatted as `Controller#action`. This value is
  stored and passed along as the third argument to the `:stop` callback.

  When called with the atom `:stop` this is used as the Stop callback for
  Phoenix controllers. Phoenix calls it after the whole controller pipeline
  finishes executing the routed action. You should additionally provide the
  elapsed_time and the Transaction as the second and third arguments.
  """
  @spec phoenix_controller_call(:start, %{}, %Plug.Conn{}) :: transaction :: binary()
  def phoenix_controller_call(:start, _compile_metadata, %{conn: conn}) do
    if NewRelixir.active? do
      transaction = Utils.transaction_name(conn)
      CurrentTransaction.set(transaction)
      transaction
    end
  end

  @spec phoenix_controller_call(:stop, integer(), transaction :: binary()) :: :ok | nil
  def phoenix_controller_call(:stop, elapsed_time, transaction) do
    if NewRelixir.active? do
      elapsed_microseconds = System.convert_time_unit(elapsed_time, :native, :microsecond)

      Transaction.record_web(transaction, elapsed_microseconds)
    end
  end
end
