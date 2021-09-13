#/bin/sh

# Loading config
SCRIPTPATH="$(dirname "$(readlink -f "$0")")"
. "$SCRIPTPATH"/opt.cfg
. "$SCRIPTPATH"/check_installed.sh

# make temp dir
# WORKDIR="./result/$1"
WORKDIR="$HOME/.hack/$1.`date '+%Y%m%d'`"
mkdir -p $WORKDIR 

# create domain list
echo $1|anew "$WORKDIR/domain_lst"


# ======================= FUNCTIONS =======================

function pr {
	if [ -n "$1" ] && [ -n "$2" ]; then
		case $1 in
			info)
				echo -e "\n${bblue}${2} ${reset}" | tee $WORKDIR/summary
			;;
			cmd)
				if [ -n "$3" ]; then
					echo -e "${yellow}  [${2}] ${gray} ${3} ${reset}" | tee $WORKDIR/summary
				else
					echo -e "${gray}  ${2} ${reset}" | tee $WORKDIR/summary
				fi
			;;
		esac
	fi
}

function resolveIP {
	# https://github.com/Josue87/resolveDomains
	# > resolveDomains -d domainFiles.txt [-t 150] [-r 8.8.8.8:53]
	command="resolveDomains -d $1 $resolveDomains_thread $resolveDomains_dns"
	pr cmd "resolveDomains" "> $command"
	eval $command \
			| awk '{print $2}'\
			| anew $anew_opt "$WORKDIR/ip_lst" 
}

function portscanning {
	# GO111MODULE=on go get -v github.com/projectdiscovery/naabu/v2/cmd/naabu
	command="naabu -iL $1 $naabu_opt"
	pr cmd "naabu" "> $command"
	eval $command  | grep -v \* | anew $anew_opt "$WORKDIR/target_ports"
}

function subdomain {
	for domain in `cat $1`; do

		# ---- crt.sh
		crtsh="curl -s \"https://crt.sh/?Identity=%.$domain\""
		pr cmd "crt.sh" "> $crtsh"

		eval $crtsh  | grep ">*.$domain" 			\
				| sed 's/<[/]*[TB][DR]>/\n/g' 		\
				| grep -vE "<|^[\*]*[\.]*$domain" 	\
				| sort -u | uniq 					\
				| awk 'NF' | grep --color $domain 	\
				| anew $anew_opt "$WORKDIR/subdomain"

		# ---- certspotter
		certspotter="curl -s \"https://api.certspotter.com/v1/issuances?domain=$domain&expand=dns_names&expand=issuer\""

		pr cmd "certspotter" "> $certspotter"
		eval $certspotter 	| jq .[].dns_names[] 				\
							| tr -d '\", ' 						\
							| sort -u|uniq|grep --color $domain \
							| anew $anew_opt "$WORKDIR/subdomain"

	done
}

function techdetection {
	# ---- httprobe
	command="cat $1 | httprobe $httprobe_opt"
	pr cmd "httprobe" "> $command"
	eval $command | anew $anew_opt "$WORKDIR/alive"
	# ---- httpx
	# GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx
	command="cat $1 | httpx $httpx_opt"
	pr cmd "httpX" "> $command"
	eval $command | anew $anew_opt "$WORKDIR/techz" 
}

function vulnscan {
	# ---- nuclei
	command="nuclei -l $1 $target $nuclei_opt"
	pr cmd "nuclei" "> $command"
	eval $command | anew "$WORKDIR/nuclei.log" 

	# ---- jaeles
	command="jaeles scan -U $1 $jaeles_opt -o $WORKDIR/jaeles.out/"
	pr warn "[jaeles]"
	eval $command | anew "$WORKDIR/jaeles.log" 
}

function discover_path {
	command="ffuf -w \"$1:HOST\" $ffuf_opt -u \"HOST/FUZZ\""
	pr cmd 'ffuf' "> $command"
	eval $command >> "$WORKDIR/ff.out"
}


function jsfinding {
	for target in `cat $1`; do
		host=$( echo $target | awk -F '://' '{print $2}' | grep -Eo '^[^\/]*' )
		output="$WORKDIR/js"
		mkdir -p $output

		# ---- gau
		command="gau $target -subs"
		pr cmd 'gau' "> $command"
		eval $command 	| cut -d"?" -f1 			\
						| grep -E "\.js+(?:on|)$" 	\
						| sort -u |uniq \
						| anew $anew_opt "$output/jsurls.txt"
		
		# ---- fff
		command="sort $output/jsurls.txt |uniq| fff $fff_opt -o $output/saved/"
		pr cmd 'fff' "> $command"
		eval $command

		# ---- gf
		command="for pattern in \`gf -list\`; do [[ ${pattern} =~ "_secrets"* ]] && gf ${pattern} $output/saved/; done"
		pr cmd 'gf' "> $command"
		for pattern in `gf -list`; do 
			[[ ${pattern} =~ "_secrets"* ]]
			gf ${pattern} $output/saved/ | anew "$output/secret"
		done

		# ---- xkeys
		cat $output/jsurls.txt | xkeys | anew "$output/secret"
	done
}


# ======================= MAIN =======================

HOST=${1:-/dev/stdin}
pr info "[+] Target $HOST"

pr info "[Step 1: 1/2] Resolving IP > $WORKDIR/ip_lst"
resolveIP "$WORKDIR/domain_lst"

pr info "[Step 1: 2/2] Scanning port by IP > $WORKDIR/target_ports"
portscanning "$WORKDIR/ip_lst"


pr info "[Step 2: 1/2] Discover subdomain > $WORKDIR/subdomain"
subdomain "$WORKDIR/domain_lst"

pr info "[Step 2: 2/2] Scanning port by domain > $WORKDIR/target_ports"
portscanning "$WORKDIR/subdomain"


pr info "[Step 3: 1/2] Detect web app > $WORKDIR/techz"
techdetection "$WORKDIR/target_ports"


pr info "[Step 4] Scanning vulnerability > $WORKDIR/vulns"
vulnscan "$WORKDIR/alive"

pr info "[Step 5: 1/2] Discover path > $WORKDIR/ff.out"
discover_path "$WORKDIR/alive"

pr info "[Step 5: 2/2] Discover js > $WORKDIR/js/"
jsfinding "$WORKDIR/alive"