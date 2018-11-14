defmodule Project3 do
  alias Project3.Node
  use GenServer

  def start_link args do
    GenServer.start_link __MODULE__, args, name: :Server
  end

  def init args do
    {num_nodes, num_requests} = args
    # state = {num_nodes, num_requests, total_hops}
    {:ok, {num_nodes, num_requests, 0}}
  end

  def main argv do
    [num_nodes, num_requests, failure_rate] = argv

    num_nodes = num_nodes |> String.to_integer
    num_requests = num_requests |> String.to_integer
    failure_rate = failure_rate |> String.to_integer

    number_of_failure_nodes = (failure_rate/100)*num_nodes |> round

    start_link {num_nodes, num_requests}
    create_network num_nodes, num_requests, number_of_failure_nodes
    Process.sleep :infinity
  end

  def create_network num_nodes, num_requests, number_of_failure_nodes do

    failure_nodes = Enum.take_random(1..num_nodes, number_of_failure_nodes)
    failure_nodes = failure_nodes |> Enum.sort
    #IO.inspect failure_nodes
    Enum.each 1..num_nodes, fn node_no ->
      Node.start_link {node_no, num_requests, num_nodes, failure_nodes}
    end

  end

  def handle_cast {:message_delivered, hop_count}, state do
    {n, r, total_hops} = state
    new_state = {n, r, total_hops + hop_count}
    {:noreply, new_state}
  end

  def handle_cast {:node_finished, total_nodes}, state do
    {num_nodes, num_requests, total_hops} = state
    remaining_nodes = num_nodes - 1

    if remaining_nodes == 0 do
      avg_hops = total_hops / (total_nodes * num_requests)
      failure_count = Node.get_failure_count()
      IO.puts "Average number of hops is #{avg_hops}"
      #IO.puts "Failures occured = #{failure_count}"
      System.halt(0)
    end

    new_state = {remaining_nodes, num_requests, total_hops}
    {:noreply, new_state}
  end
end
