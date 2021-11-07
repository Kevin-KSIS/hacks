function jsfinding {
	for target in `cat $1`; do
		host=$( echo $target | awk -F '://' '{print $2}' | grep -Eo '^[^\/]*' )
		output="$WORKDIR/fuzz"
		mkdir -p $output

		# ---- gau
		command="gau $gau_opt $target -subs"
		pr cmd 'gau' "$output/allurls.txt" "$command"
		sh -c "$command"  	| cut -d"?" -f1 			\
							|sort|uniq| anew $anew_opt "$output/allurls.txt"

		pr cmd 'gau' "$output/jsurls.txt" "$command"
		grep -E "\.js+(?:on|)$" "$output/allurls.txt"	\
							|sort|uniq| anew $anew_opt "$output/jsurls.txt"
		
		# ---- fff
		command="sort $output/jsurls.txt |uniq| fff $fff_opt -o $output/js_saved/ 1>/dev/null"
		pr cmd 'fff' "$output/js_saved/" "$command"
		sh -c "$command" 

		# ---- gf
		command="for pattern in \`gf -list\`; do [[ \${pattern} =~ "_secrets"* ]] && gf \${pattern} $output/js_saved/; done"
		pr cmd 'gf' ""$output/secret"" "$command"
		for pattern in `gf -list`; do 
			[[ ${pattern} =~ "_secrets"* ]] && gf ${pattern} $output/js_saved/ | anew "$output/secret"
		done
	done

	# ---- xkeys
	command="cat $output/jsurls.txt | xkeys"
	pr cmd 'xkeys' "$output/secret" "$command"
	sh -c "$command"  | anew "$output/secret"
}