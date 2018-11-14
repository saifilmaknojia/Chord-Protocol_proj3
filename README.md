GROUP INFO

Jacob Ville			4540-7373<br>
Shaifil Maknojia	7805-9466<br>

***

#### Instructions:

1. Extract the zip file
2. Go to project3 folder
3. mix escript.build
4. ./project3 num_nodes num_requests<br>

    num_nodes    - integer<br>
    num_requests - integer<br>

	Eg:  <br>
	\DOS\Projects\project3 <br>
	\DOS\Projects\project3> mix escript.build <br>
	\DOS\Projects\project3> ./project3 1200 15<br>
	
	O/P: <br>
    Average number of hops is 4.95
	
***

#### Bonus Instructions:

usage: ./project3 num_nodes num_requests failure_rate<br>

failure_rate    - integer (0 - 100)<br>

***

#### What is working:

The chord protocol is working as specified in the paper. Nodes are created and initialized with a finger table referencing other nodes in the network. Once all nodes are initialized they begin to send messages to a random key that is mapped to a node. Each time the message is sent and received, the number of hops increases, and is recorded once it reaches its destination.

To verify output and observe traversal, uncomment line #33 in lib/node.exs

***

#### Largest Network:

The largest network used had 250,000 nodes. After that our systems exceeded the max number of simultaneous processes.
