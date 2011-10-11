## Dropbox 'File Events' Challenge

_As seen on http://www.dropbox.com/jobs/challenges#file-events_

### About 
This is my attempt to solve this challenge with a quick implementation in Erlang as an escript app.
It's not (yet) an OTP app, rather a quick proof of concept that using a state-machine is appropriate (gen_fsm in an OTP context).
What to do (emit notifications) is deduced when changing state (incoming events) and identifying patterns (combinations of 
events) that appeared in a particular order.

### Usage
The erlang script in `src/event_reader.erl` reads data from `STDIN`.

    cat data/add.txt | escript src/event_reader.erl []

Test data is in `data/`. You can run `python data/gen_data.py` to quickly generate a 50k, dummy-events file
and test that load on the script.

### Assumptions
* Events come in order, and this order is important.
* Atomic operations are : add(`ADD`), delete(`DEL`)
* Compound operations are: rename(`DEL`+`ADD`), move(`DEL`+`ADD`)

### What should have been done
* Eunit tests
* specs

### Improvements
* Notifications are emitted for every file inside a folder when operating on a folder. This is noise ...
* Convert to an OTP app using gen_fsm
