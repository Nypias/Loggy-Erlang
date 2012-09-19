-module(logger).
-export([start/1, stop/1]).

start(Nodes) ->
    spawn(fun() ->
		  init(Nodes) end).

stop(Logger) ->
    Logger ! stop.

% Nodes = [paul, ringo, george, john]
% Creation of lists of list
% [{john, []}, {george, []}, {ringo, []}, {paul, []}]
init(Nodes) ->
    Queue = lists:foldl(fun(X, Acc) -> [{X, []}|Acc] end, [], Nodes),
    loop(Queue).


loop(Queue) ->
    receive
	{log, From, TimeCurr, Msg} ->

	    % Entry = {john, [{1, Message}, {2, Message}]}
	    Entry = lists:keyfind(From, 1, Queue),

	    {_, ListEntry} = Entry,    % We add the received message into the list
	    
	    case ListEntry of
		[] ->
		    NewQueue = lists:keyreplace(From, 1, Queue, {From, ListEntry++[{TimeCurr, Msg}]});
		    
		_ ->
		    %io:format("From : - ~w~n", [From]),
		    {TimeLast, _} = lists:last(ListEntry),
		    case TimeCurr > TimeLast of
			true ->
			    NewQueue = lists:keyreplace(From, 1, Queue, {From, ListEntry++[{TimeCurr, Msg}]});
			false ->
			    NewQueue = Queue
		    end
			
	    end,

	    NextQueue = log(NewQueue),
	    loop(NextQueue);
	stop ->
	    ok
    end.

log(Queue) ->
    %io:format("== LOG == ~n~n"),
    %io:format('~w~n~n', [Queue]),
    % We look if all lists are full (one element at least per list)
    case lists:keyfind([], 2, Queue) of
	false ->

    % If so, we take the smaller message in one of the list
	    SmallerMessage = lists:foldl(fun({X, ListX}, Acc) -> 
						 {CurrTime, Msg} = lists:nth(1,ListX),
						 case Acc of
						     {} ->
							 {X, CurrTime, Msg};
						     {_,AccTime, _} ->
							 if CurrTime < AccTime -> {X, CurrTime, Msg};
							    true -> Acc end
						 end
					 end,
					 {}, Queue),

            % We print the message
	    {From, Time, Msg} = SmallerMessage,
	    io:format("log : ~w ~w ~p~n", [From, Time, Msg]),
	    
            % We remove from the list
	    NewQueue = lists:foldl(fun(X, Acc) -> 
					   {Name, List} = X,
					   if (Name == From) ->
						   [{Name,lists:keydelete(Time, 1, List)} | Acc];
					      true -> [{Name, List} | Acc]
					   end
				   end,
			[], Queue),

            % We call again log()
	    log(NewQueue);
	_ -> Queue
    end.



