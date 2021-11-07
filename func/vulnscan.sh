function nuclei {
	command="nuclei -l $1 $target $nuclei_opt"
	pr cmd "nuclei" "$WORKDIR/vulns/nuclei.log"  "$command"
	sh -c "$command"  | anew "$WORKDIR/vulns/nuclei.log" 
}

function jaeles {
	command="jaeles scan -U $1 $jaeles_opt -o $WORKDIR/vulns/jaeles.out/ \
			--html $WORKDIR/vulns/jaeles-report.html"
	pr cmd "jaeles" "$WORKDIR/vulnsjaeles.log" "$command"
	sh -c "$command"  | anew "$WORKDIR/vulns/jaeles.log" 
}


function subzy {
	# ---- subzy
	command="subzy $subzy_opt -targets $WORKDIR/subdomain"
	pr cmd 'subzy' "$WORKDIR/vulns/takeover" "$command"
	sh -c "$command"  | anew "$WORKDIR/vulns/takeover"
}