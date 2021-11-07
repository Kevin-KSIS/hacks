function httprobe {
	command="cat $1 | httprobe $httprobe_opt"
	pr cmd "httprobe" "$WORKDIR/alive" "$command"
	sh -c "$command"  | anew $anew_opt "$WORKDIR/alive"
	
}

function httpx {
	# GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx
	command="cat $1 | httpx $httpx_opt"
	pr cmd "httpX" "$WORKDIR/techz" "$command"
	sh -c "$command"  | anew "$WORKDIR/techz" 
}