#!/usr/bin/env escript
%% -*- erlang -*-

-module(event_reader).
-record(file, {path, hash, name, dirname}).

%% Main entry point of the program
%% reads STDIN for data
main([_]) ->
    register(proc, self()),
    {ok, [N]} = io:fread("", "~d\n"),
    io:format("Reading ~p events from file ...~n", [N]),
    spawn(fun() -> read(N) end),
    consume(queue:new()).
    
%% read lines of the data submitted in STDIN
read(0) ->
    proc ! eof;
read(N) ->
    case io:fread("", "~s ~d ~s ~s\n") of
        eof -> {error, "EOF while lines have to be read"};
        {ok, [Evt,_,Path,Hash]} -> 
                        E = case Evt of "ADD" -> file_add; "DEL" -> file_delete end,
                        F = #file{path=Path, 
                                  hash=Hash,
                                  name=filename:basename(Path),
                                  dirname=filename:dirname(Path) },
                        proc ! {E, F},
                        read(N-1)
    end.

%% consume the messages left in the mailbox by the 'read' process
consume(Q) ->
    receive
        eof -> 
            flush(Q),
            io:format("~n -EOF- ~n");
        
        {file_delete, FileDel} -> 
            consume(queue:in(FileDel, Q));
        
        {file_add, #file{name=NameAdd, dirname=DirnameAdd}=FileAdd} ->
            Q2Consume = case compare(Q, FileAdd) of
                {Q2, deleted_created, _} -> 
                    io:format("(-+) ~p was deleted then created in ~p~n", [NameAdd, DirnameAdd]),
                    Q2;
                    
                {Q2, updated, _} -> 
                    io:format("(+1) ~p was updated~n", [NameAdd]),
                    Q2; 
                    
                {Q2, moved, #file{dirname=DirnameDel}}  -> 
                    io:format("(>) ~p was moved from ~p to ~p~n", [NameAdd, DirnameDel, DirnameAdd]),
                    Q2;
                    
                {Q2, renamed, #file{name=NameDel}}  -> 
                    io:format("(|) ~p was renamed to ~p~n", [NameDel, NameAdd]),
                    Q2;  
                    
                {Q2, created}  -> 
                    io:format("(+) ~p was created in ~p~n", [NameAdd, DirnameAdd]),
                    Q2
            end,
            consume(Q2Consume)  
    end.

%% Q is a queue used to store previous DEL ops. It acts a the state of our event reading.
%% Dequeuing allows to consult the previous operation in order to detect the type of 
%% 
%% add > ADD
%% delete > DEL
%% rename > DEL + ADD
%% move > DEL + ADD
compare(Q, #file{name=NameAdd, dirname=DirnameAdd, path=PathAdd, hash=HashAdd}=FileAdded) ->
    case queue:out(Q) of
        % same path, same hash = deleted then recreated
        {{value, #file{hash=HashAdd, path=PathAdd}=FileDel}, Q2} -> 
            {Q2, deleted_created, FileDel};
        
        % file:same path, different hash = updated
        {{value, #file{path=PathAdd}=FileDel}, Q2} -> 
            {Q2, updated, FileDel};
        
        % same name, same hash. diff. dirname = moved
        {{value, #file{hash=HashAdd, name=NameAdd}=FileDel}, Q2} -> 
            {Q2, moved, FileDel};

        % same path, diff. name = renamed,
        {{value, #file{hash=HashAdd, dirname=DirnameAdd}=FileDel}, Q2} -> 
            {Q2, renamed, FileDel};

        % something that doesnt match ? maybe Deleted  file was really deleted
        {{value, #file{name=NameDel, dirname=DirnameDel}}, Q2} -> 
            io:format("(-) ~p was deleted from ~p ~n", [NameDel, DirnameDel]),
            compare(Q2, FileAdded);
        
        % empty
        {empty, Q} -> {Q, created}
    end.

%% When our reading ends, flush the queue to get the latest DEL operations
flush(Q) ->
    compare(Q, #file{}).