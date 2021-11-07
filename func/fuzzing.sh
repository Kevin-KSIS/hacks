function ffuf {
	command="ffuf -w \"$1:HOST\" $ffuf_opt -u \"HOST/FUZZ\" -o $WORKDIR/ffuf.html -od $WORKDIR/ffuf_save"
	pr cmd 'ffuf' "$WORKDIR/ffuf.html" "> $command"
	sh -c "$command" 
}