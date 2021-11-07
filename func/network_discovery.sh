function naabu {
	# GO111MODULE=on go get -v github.com/projectdiscovery/naabu/v2/cmd/naabu
	command="naabu -iL $1 $naabu_opt"
	pr cmd "naabu" "$WORKDIR/target_ports" "$command"
	sh -c "$command" | anew $anew_opt "$WORKDIR/target_ports"
}