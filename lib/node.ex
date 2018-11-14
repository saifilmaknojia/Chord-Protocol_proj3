defmodule Project3.Node do
  use GenServer

  def start_link args do
    {node_no, _, _} = args
    GenServer.start_link __MODULE__, args, name: :"#{node_no}"
  end

  def init args do
    {node_no, num_requests, num_nodes} = args
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

    {:ok, {node_no, num_requests, num_nodes, fngr_tbl}}
  end

  def handle_cast {:send, {dest, hop_count}}, state do
    {node_no, _, _, fngr_tbl} = state

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
    {node_no, num_requests, num_nodes, fngr_tbl} = state

    if num_requests == 0 do
      GenServer.cast :Server, {:node_finished, num_nodes}
      {:noreply, state}
    else
      dest = Enum.random 1..(num_nodes*5)
      if dest > num_nodes do
        dest = rem(dest, num_nodes)
        GenServer.cast String.to_atom("#{node_no}"), {:send, {dest, 0}}
      else
        GenServer.cast String.to_atom("#{node_no}"), {:send, {dest, 0}}
      end


      schedule_request()
      new_state = {node_no, num_requests-1, num_nodes, fngr_tbl}
      {:noreply, new_state}
    end
  end

  defp schedule_request do
    Process.send_after self(), :new_request, 1000
  end
end
