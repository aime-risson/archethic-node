defmodule Archethic.BeaconChain.SummaryAggregateTest do
  use ArchethicCase

  alias Archethic.BeaconChain.Summary
  alias Archethic.BeaconChain.SummaryAggregate
  alias Archethic.P2P
  alias Archethic.P2P.Node
  alias Archethic.BeaconChain.ReplicationAttestation
  alias Archethic.TransactionChain.TransactionSummary

  import Mock

  doctest SummaryAggregate

  setup do
    P2P.add_and_connect_node(%Node{
      first_public_key: <<0::8, 0::8, 0::8, :crypto.strong_rand_bytes(31)::binary>>,
      last_public_key: <<0::8, 0::8, 0::8, :crypto.strong_rand_bytes(31)::binary>>,
      ip: {127, 0, 0, 1},
      port: 3000
    })

    P2P.add_and_connect_node(%Node{
      first_public_key: <<0::8, 0::8, 0::8, :crypto.strong_rand_bytes(31)::binary>>,
      last_public_key: <<0::8, 0::8, 0::8, :crypto.strong_rand_bytes(31)::binary>>,
      ip: {127, 0, 0, 1},
      port: 3001
    })

    :ok
  end

  describe "aggregate/1" do
    test "should aggregate multiple network patches into a single one" do
      assert %SummaryAggregate{
               p2p_availabilities: %{
                 <<0>> => %{
                   node_availabilities: <<>>,
                   node_average_availabilities: [],
                   end_of_node_synchronizations: [],
                   network_patches: ["ABC", "DEF"]
                 }
               }
             } =
               %SummaryAggregate{
                 p2p_availabilities: %{
                   <<0>> => %{
                     node_availabilities: [],
                     node_average_availabilities: [],
                     end_of_node_synchronizations: [],
                     network_patches: [["ABC", "DEF"], ["ABC", "DEF"]]
                   }
                 }
               }
               |> SummaryAggregate.aggregate()
    end

    test "should aggregate multiple different network patches into a single one" do
      assert %SummaryAggregate{
               p2p_availabilities: %{
                 <<0>> => %{
                   node_availabilities: <<>>,
                   node_average_availabilities: [],
                   end_of_node_synchronizations: [],
                   network_patches: ["BA6", "DEF"]
                 }
               }
             } =
               %SummaryAggregate{
                 p2p_availabilities: %{
                   <<0>> => %{
                     node_availabilities: [],
                     node_average_availabilities: [],
                     end_of_node_synchronizations: [],
                     network_patches: [
                       ["ABC", "DEF"],
                       ["C90", "DEF"],
                       ["FFF", "DEF"],
                       ["000", "DEF"]
                     ]
                   }
                 }
               }
               |> SummaryAggregate.aggregate()
    end
  end

  describe "add_summary/2" do
    setup_with_mocks [
      {ReplicationAttestation, [], validate: fn _ -> :ok end}
    ] do
      attestation = %ReplicationAttestation{
        transaction_summary: %TransactionSummary{address: "addr1"}
      }

      attestation2 = %ReplicationAttestation{
        transaction_summary: %TransactionSummary{address: "addr2"}
      }

      aggregate = %SummaryAggregate{
        replication_attestations: [attestation],
        p2p_availabilities: %{
          <<0>> => %{
            node_availabilities: [[1, 0]],
            node_average_availabilities: [[0.95, 0.7]],
            end_of_node_synchronizations: [],
            network_patches: [["ABC", "DEF"]]
          }
        }
      }

      {:ok, %{aggregate: aggregate, attestation2: attestation2}}
    end

    test "should add summary into aggregate", %{
      aggregate: aggregate = %SummaryAggregate{replication_attestations: previous_attestations},
      attestation2: attestation2
    } do
      summary = %Summary{
        subset: <<0>>,
        node_availabilities: <<1::1, 1::1>>,
        node_average_availabilities: [1, 0.8],
        network_patches: ["DEF", "ABC"],
        transaction_attestations: [attestation2]
      }

      assert %SummaryAggregate{
               replication_attestations: [^attestation2 | ^previous_attestations],
               p2p_availabilities: %{
                 <<0>> => %{
                   node_availabilities: [[1, 0], [1, 1]],
                   node_average_availabilities: [[0.95, 0.7], [1, 0.8]],
                   end_of_node_synchronizations: [],
                   network_patches: [["ABC", "DEF"], ["DEF", "ABC"]]
                 }
               }
             } = SummaryAggregate.add_summary(aggregate, summary)
    end

    test "should not add p2p view when summary one is invalid", %{
      aggregate: aggregate = %SummaryAggregate{replication_attestations: previous_attestations},
      attestation2: attestation2
    } do
      summary = %Summary{
        subset: <<0>>,
        node_availabilities: <<1::1>>,
        node_average_availabilities: [0.8],
        network_patches: ["DEF", "ABC"],
        transaction_attestations: [attestation2]
      }

      assert %SummaryAggregate{
               replication_attestations: [^attestation2 | ^previous_attestations],
               p2p_availabilities: %{
                 <<0>> => %{
                   node_availabilities: [[1, 0]],
                   node_average_availabilities: [[0.95, 0.7]],
                   end_of_node_synchronizations: [],
                   network_patches: [["ABC", "DEF"], ["DEF", "ABC"]]
                 }
               }
             } = SummaryAggregate.add_summary(aggregate, summary)
    end
  end
end
