function resolveIP {
	# https://github.com/Josue87/resolveDomains
	# > resolveDomains -d domainFiles.txt [-t 150] [-r 8.8.8.8:53]
	command="resolveDomains -d $1 $resolveDomains_thread $resolveDomains_dns"
	pr cmd "resolveDomains" "$WORKDIR/ip_lst" "$command"
	sh -c "$command"  \
			| awk '{print $2}'\
			| anew $anew_opt "$WORKDIR/ip_lst" 
}

function crtsh {
	for domain in `cat $1`; do

		command="curl -s \"https://crt.sh/?Identity=%.$domain\""
		pr cmd "crt.sh" "$WORKDIR/subdomain" "$command"

		sh -c "$command"   | grep ">*.$domain" 			\
				| sed 's/<[/]*[TB][DR]>/\n/g' 		\
				| grep -vE "<|^[\*]*[\.]*$domain" 	\
				| sort -u | uniq 					\
				| awk 'NF' | grep --color $domain 	\
				| anew $anew_opt "$WORKDIR/subdomain"
	done
}

function certspotter {
	for domain in `cat $1`; do
		command="curl -s \"https://api.certspotter.com/v1/issuances?domain=$domain&expand=dns_names&expand=issuer\""

		pr cmd "certspotter" "$WORKDIR/subdomain" "$command"
		sh -c "$command"  	| jq .[].dns_names[] 				\
							| tr -d '\", ' 						\
							| sort -u|uniq|grep --color $domain \
							| anew $anew_opt "$WORKDIR/subdomain"

	done
}