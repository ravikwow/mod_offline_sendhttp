%%%----------------------------------------------------------------------
%%% File    : mod_offline_sendhttp.erl
%%% Author  : Ravil Khabiakhmetov (ravikwow@gmail.com) 
%%%           forked from Robert George <rgeorge@midnightweb.net>
%%%----------------------------------------------------------------------

-module(mod_offline_sendhttp).
-author('ravikwow@gmail.com').
-behaviour(gen_mod).

-export([start/2,
	init/2,
	stop/1,
	send_notice/3]).

-define(PROCNAME, ?MODULE).

-include("ejabberd.hrl").
-include("jlib.hrl").

start(Host, Opts) ->
	?INFO_MSG("Starting mod_offline_sendhttp", [] ),
	register(?PROCNAME,spawn(?MODULE, init, [Host, Opts])),  
	ok.

init(Host, _Opts) ->
	inets:start(),
	ssl:start(),
	ejabberd_hooks:add(offline_message_hook, Host, ?MODULE, send_notice, 10),
	ok.

stop(Host) ->
	?INFO_MSG("Stopping mod_offline_sendhttp", [] ),
	ejabberd_hooks:delete(offline_message_hook, Host, ?MODULE, send_notice, 10),
	ok.

send_notice(_From, To, Packet) ->
	Type = xml:get_tag_attr_s("type", Packet),
	FromS = xml:get_tag_attr_s("from", Packet),
	ToS   = xml:get_tag_attr_s("to", Packet),
	Body = xml:get_path_s(Packet, [{elem, "body"}, cdata]),
	Url_SendHTTP = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, url, []),
	if
		(Type == "chat") and (Body /= "") ->
			Sep = "&",
			Post = [
				"body=", Body, Sep,
				"from=", string:sub_word(FromS,1,$/), Sep,
				"to=", string:sub_word(ToS,1,$/), Sep ],
			http:request(post, {Url_SendHTTP, [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
			ok;
		true ->
			ok
	end.

