key ownerKey = NULL_KEY;
string ownerName = "";
string url = "";
integer userChannel = PUBLIC_CHANNEL;
key httpRequestKey = NULL_KEY;
string accessToken = "";
string command = "";
string search = "";

integer DEBUG = 1;
integer SECRET_NONCE = 123456789;
string SECRET_HASH = "SECRET_HASH";
string HTTP_PROTOCOL = "https://";
string HTTP_USER = "HTTP_USER";
string HTTP_PASSWORD = "HTTP_PASSWORD";
string HTTP_URL = "your.domain/spotify/";

list HTTP_PARAMETERS = [
	HTTP_METHOD, "POST",
	HTTP_MIMETYPE, "application/x-www-form-urlencoded",
	HTTP_BODY_MAXLENGTH, 16384
];

string COMMAND_RESET = "reset";
string COMMAND_TOKEN = "token";
string COMMAND_SEARCH = "search";

on_state_entry() {

	ownerKey = llGetOwner();
	ownerName = llKey2Name(ownerKey);

	string basicAuth = llEscapeURL(HTTP_USER) + ":" + llEscapeURL(HTTP_PASSWORD);
	url = HTTP_PROTOCOL
		// + basicAuth + "@" // Uncomment in LSLEditor
		+ HTTP_URL;
	HTTP_PARAMETERS = HTTP_PARAMETERS + [HTTP_CUSTOM_HEADER, "Authorization", "Basic " + llStringToBase64(basicAuth)];

	userChannel = (integer)(llFrand(1000000000.0) + 1000000000.0);
	llListen(userChannel, ownerName, ownerKey, "");
}

string build_body() {
	string body = "uuid=" + llEscapeURL((string) ownerKey);
	if (command == COMMAND_SEARCH) {
		body += "&token=" + llEscapeURL(accessToken);
		body += "&search=" + llEscapeURL(search);
	}
	return body;
}

string build_hash(string body) {
	return llMD5String(body + llEscapeURL(SECRET_HASH), SECRET_NONCE);
}

key build_http_request() {
	string body = build_body();
	string temp = url + "?hash=" + build_hash(body);
	if (DEBUG) {
		llOwnerSay("url: " + temp);
		llOwnerSay("body: " + body);
	}
	return llHTTPRequest(temp, HTTP_PARAMETERS, body);
}

on_listen(integer channel, string name, key id, string message) {

	if (channel == userChannel) {

		message = llToLower(llStringTrim(message, STRING_TRIM));
		list p = llParseString2List(message, [" "], []);
		integer length = llGetListLength(p);
		string cmd = llStringTrim(llList2String(p, 0), STRING_TRIM);

		if (cmd == COMMAND_RESET) {
			llResetScript();

		} else if (cmd == COMMAND_TOKEN) {

			if (httpRequestKey == NULL_KEY) {

				command = cmd;
				httpRequestKey = build_http_request();

			} else {
				llOwnerSay("A request is already queued, please retry in a few minutes.");
			}

		} else if (cmd == COMMAND_SEARCH) {

			if (httpRequestKey == NULL_KEY) {
				if (length >= 2) {
					if (accessToken != "") {
						
						command = cmd;
						search = llStringTrim(llDumpList2String(llList2List(p, 1, length - 1), " "), STRING_TRIM);
						// llOwnerSay(search);
						httpRequestKey = build_http_request();
						
					} else {
						llOwnerSay("Please request a new access token.");
					}
				} else {
					llOwnerSay("Not enough parameters, usage: /" + (string) userChannel + " " + COMMAND_SEARCH + " <text>");
				}
			} else {
				llOwnerSay("A request is already queued, please retry in a few minutes.");
			}
		} else {
			llOwnerSay("Unknown command!");
		}
	}
}

on_http_response(key request_id, integer status, list metadata, string body) {

	if (command == COMMAND_TOKEN) {

		accessToken = body; // Store the access token
		llOwnerSay("Access token successfully stored.");

	} else if (command == COMMAND_SEARCH) {

		body = llStringTrim(body, STRING_TRIM);
		list p = llParseString2List(body, ["|"], []);

		integer length = llGetListLength(p);
		if (length > 0) {

			llOwnerSay("Results for \"" + search + "\": ");
			integer i = 0;
			for (i = 0; i < length; i++) {
				list l = llParseString2List(llList2String(p, i), [","], []);
				llOwnerSay(llList2String(l, 1) + " (" + llList2String(l, 2) + ")");
			}

		} else {
			llOwnerSay("No results found for \"" + search + "\".");
		}
		search = "";
	}
	command = "";
}

usage() {
	llOwnerSay("Hello! (channel = " + (string) userChannel + ")");
	llOwnerSay("/" + (string) userChannel + " token");
	llOwnerSay("/" + (string) userChannel + " search <text>");
}

default {

	state_entry() {
		on_state_entry();
		usage();
	}

	attach(key attached) {
		if (attached) {
			usage();
		}
	}

	listen(integer channel, string name, key id, string message) {
		if (DEBUG) {
			llOwnerSay("channel: " + (string) channel);
			llOwnerSay("name: " + name);
			llOwnerSay("id: " + (string) id);
			llOwnerSay("message: " + message);
		}
		on_listen(channel, name, id, message);
	}

	http_response(key request_id, integer status, list metadata, string body) {
		if (DEBUG) {
			llOwnerSay("request_id: " + (string) request_id);
			llOwnerSay("status: " + (string) status);
			llOwnerSay("metadata: " + llDumpList2String(metadata, ","));
			llOwnerSay("body: " + body);
		}
		if (httpRequestKey == request_id) {
			if (status != 200) {
				llOwnerSay("HTTP error (status: " + (string) status + ")");
			} else {
					on_http_response(request_id, status, metadata, body);
			}
			httpRequestKey = NULL_KEY;
		}
	}
}
