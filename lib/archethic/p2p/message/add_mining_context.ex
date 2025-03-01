defmodule Archethic.P2P.Message.AddMiningContext do
  @moduledoc """
  Represents a message to request the add of the context of the mining from cross validation nodes
  to the coordinator
  """
  @enforce_keys [
    :address,
    :validation_node_public_key,
    :chain_storage_nodes_view,
    :beacon_storage_nodes_view,
    :io_storage_nodes_view,
    :previous_storage_nodes_public_keys
  ]
  defstruct [
    :address,
    :validation_node_public_key,
    :chain_storage_nodes_view,
    :beacon_storage_nodes_view,
    :io_storage_nodes_view,
    :previous_storage_nodes_public_keys
  ]

  alias Archethic.Crypto
  alias Archethic.Mining
  alias Archethic.P2P.Message
  alias Archethic.P2P.Message.Ok
  alias Archethic.TaskSupervisor
  alias Archethic.Utils

  @type t :: %__MODULE__{
          address: Crypto.versioned_hash(),
          validation_node_public_key: Crypto.key(),
          chain_storage_nodes_view: bitstring(),
          beacon_storage_nodes_view: bitstring(),
          io_storage_nodes_view: bitstring(),
          previous_storage_nodes_public_keys: list(Crypto.key())
        }

  @spec process(__MODULE__.t(), Crypto.key()) :: Ok.t()
  def process(
        %__MODULE__{
          address: tx_address,
          validation_node_public_key: validation_node,
          previous_storage_nodes_public_keys: previous_storage_nodes_public_keys,
          chain_storage_nodes_view: chain_storage_nodes_view,
          beacon_storage_nodes_view: beacon_storage_nodes_view,
          io_storage_nodes_view: io_storage_nodes_view
        },
        _
      ) do
    Task.Supervisor.async_nolink(
      TaskSupervisor,
      fn ->
        Mining.add_mining_context(
          tx_address,
          validation_node,
          previous_storage_nodes_public_keys,
          chain_storage_nodes_view,
          beacon_storage_nodes_view,
          io_storage_nodes_view
        )
      end,
      timeout: Message.get_max_timeout(),
      shutdown: :brutal_kill
    )

    %Ok{}
  end

  @spec deserialize(bitstring()) :: {t(), bitstring}
  def deserialize(<<rest::bitstring>>) do
    {tx_address, rest} = Utils.deserialize_address(rest)

    {node_public_key, <<nb_previous_storage_nodes::8, rest::bitstring>>} =
      Utils.deserialize_public_key(rest)

    {previous_storage_nodes_keys, rest} =
      Utils.deserialize_public_key_list(rest, nb_previous_storage_nodes, [])

    <<
      chain_storage_nodes_view_size::8,
      chain_storage_nodes_view::bitstring-size(chain_storage_nodes_view_size),
      beacon_storage_nodes_view_size::8,
      beacon_storage_nodes_view::bitstring-size(beacon_storage_nodes_view_size),
      io_storage_nodes_view_size::8,
      io_storage_nodes_view::bitstring-size(io_storage_nodes_view_size),
      rest::bitstring
    >> = rest

    {%__MODULE__{
       address: tx_address,
       validation_node_public_key: node_public_key,
       chain_storage_nodes_view: chain_storage_nodes_view,
       beacon_storage_nodes_view: beacon_storage_nodes_view,
       io_storage_nodes_view: io_storage_nodes_view,
       previous_storage_nodes_public_keys: previous_storage_nodes_keys
     }, rest}
  end

  @spec serialize(t()) :: bitstring()
  def serialize(%__MODULE__{
        address: address,
        validation_node_public_key: validation_node_public_key,
        chain_storage_nodes_view: chain_storage_nodes_view,
        beacon_storage_nodes_view: beacon_storage_nodes_view,
        io_storage_nodes_view: io_storage_nodes_view,
        previous_storage_nodes_public_keys: previous_storage_nodes_public_keys
      }) do
    <<address::binary, validation_node_public_key::binary,
      length(previous_storage_nodes_public_keys)::8,
      :erlang.list_to_binary(previous_storage_nodes_public_keys)::binary,
      bit_size(chain_storage_nodes_view)::8, chain_storage_nodes_view::bitstring,
      bit_size(beacon_storage_nodes_view)::8, beacon_storage_nodes_view::bitstring,
      bit_size(io_storage_nodes_view)::8, io_storage_nodes_view::bitstring>>
  end
end
