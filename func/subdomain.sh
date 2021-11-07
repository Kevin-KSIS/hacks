# REF
# 1. https://blog.appsecco.com/a-penetration-testers-guide-to-sub-domain-enumeration-7d842d5570f6


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

function sublist3r {
	for domain in `cat $1`; do
		command="$sublist3r -d $domain"

		pr cmd "sublist3r" "$WORKDIR/subdomain" "$command"
		sh -c "$command" 	| anew $anew_opt "$WORKDIR/subdomain"
	done
}

function amass_tool {
	for domain in `cat $1`; do
		command="amass enum --passive -d $domain"

		pr cmd "Amass" "$WORKDIR/subdomain" "$command"
		sh -c "$command" | anew $anew_opt "$WORKDIR/subdomain"
	done
}

# git clone https://github.com/aboul3la/Sublist3r.git

# virustotals
# amass enum --passive -d appsecco.com # Amass 3.x
# https://censys.io/
# https://developers.facebook.com/tools/ct/
# https://google.com/transparencyreport/https/ct/
# psql -h crt.sh -p 5432 -U guest certwatch