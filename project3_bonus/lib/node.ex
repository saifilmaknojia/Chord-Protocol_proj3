defmodule Project3.Node do
  use GenServer
  @name __MODULE__
  def start_link args do
    {node_no, _, _, _} = args
    GenServer.start_link __MODULE__, args, name: :"#{node_no}"
    Agent.start_link(fn -> %{a: 0} end, name: __MODULE__)
  end

  def init args do
    {node_no, num_requests, num_nodes, failure_nodes_list} = args
    schedule_request()

    m = :math.log(num_nodes)/:math.log(2) |> :math.ceil |> round
    fngr_tbl = Enum.map 0..m-1, fn i ->
      dest = :math.pow(2, i) + node_no |> round
      if dest != num_nodes do
        rem(dest, num_nodes)
      else
        dest
      end
    end

    {:ok, {node_no, num_requests, num_nodes, fngr_tbl, failure_nodes_list}}
  end

  #TODO convert to call for bonus
  def handle_cast {:send, {dest, hop_count}}, state do
    {node_no, _, _, fngr_tbl, _} = state
      if dest == node_no do
      GenServer.cast :Server, {:message_delivered, hop_count}
      else
      dest_node = get_dest_node dest, fngr_tbl
      #IO.puts "#{inspect fngr_tbl}: from: #{node_no} to #{dest_node} then #{dest}"

      GenServer.cast String.to_atom("#{dest_node}"), {:send, {dest, hop_count+1}}
      end
    {:noreply, state}
  end

  def get_dest_node dest, fngr_tbl do
    list =
      Enum.flat_map fngr_tbl, fn d ->
        case d <= dest do
          true -> [d]
          false -> []
        end
      end

    if list != [] do
      list |> Enum.max()
    else
      fngr_tbl |> Enum.max()
    end
  end

  def handle_info :new_request, state do
    {node_no, num_requests, num_nodes, fngr_tbl, failure_nodes_list} = state
    # IO.puts "No requests = #{num_requests}"
    if num_requests == 0 do
      GenServer.cast :Server, {:node_finished, num_nodes}
      {:noreply, state}
    else
      dest = Enum.random 1..(num_nodes*5)
      if Enum.member?(failure_nodes_list, dest) do
        successor_node = get_next_successor(failure_nodes_list, dest)
        # IO.puts "S = #{successor_node}"
        GenServer.cast String.to_atom("#{node_no}"), {:send, {successor_node, 0}}
      else
      if dest>num_nodes do
        # IO.puts "Dest = #{dest}"
        dest = rem(dest, num_nodes)
        GenServer.cast String.to_atom("#{node_no}"), {:send, {dest, 0}}
      else
        GenServer.cast String.to_atom("#{node_no}"), {:send, {dest, 0}}
      end
    end

      schedule_request()
      new_state = {node_no, num_requests-1, num_nodes, fngr_tbl, failure_nodes_list}
      {:noreply, new_state}
    end
  end

  def schedule_request do
    Process.send_after self(), :new_request, 1000
  end


  def update_failure_count do
    Agent.update(@name, fn map -> Map.update(map, :a, 0, &(&1+1))end)
  end

  def get_failure_count() do
    total_failures = Agent.get(@name, fn map -> Map.get(map, :a) end)
    total_failures
  end

  def get_next_successor(failure_nodes_list, new_dest) do
    if Enum.member?(failure_nodes_list, new_dest) do
      get_next_successor(failure_nodes_list, new_dest+1)
      update_failure_count()
    else
      # IO.puts "New_dest = #{new_dest}"
      new_dest
    end
  end

end
