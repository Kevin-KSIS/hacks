#/bin/sh

# ======================= INCLUDES =======================

function pr {
	case $1 in
		banner)
			echo -e "\n${bgreen}$2 ${reset}"
		;;
		info)
			echo -e "\n${bblue}${2} ${reset}"
		;;	
		error)
			echo -e "\n${red}${2} ${reset}"
		;;
		cmd)
			echo -e "$yellow [$2] $reset [$3] $gray $4 $reset"
		;;
	esac
}

SCRIPTPATH="$(dirname "$(readlink -f "$0")")"
. "$SCRIPTPATH"/opt.cfg
. "$SCRIPTPATH"/check_installed
. "$SCRIPTPATH"/func/network_discovery.sh
. "$SCRIPTPATH"/func/subdomain.sh
. "$SCRIPTPATH"/func/tech_discovery.sh
. "$SCRIPTPATH"/func/vulnscan.sh
. "$SCRIPTPATH"/func/fuzzing.sh
. "$SCRIPTPATH"/func/js_analysis.sh


# ======================= CATEGORIES =======================
function print_usage {
	# Todo: check requirement of each mode
	echo "Usage: sch -t wildcard_domain [-s single_domain] [-m <below>] [-o output_dir]"
	echo "  MODE: "
	echo -e "\tdefault: all"
	echo -e "\tsubdomain"
	echo -e "\tscanport"
	echo -e "\ttechz"
	echo -e "\tvulnscan"
	echo -e "\tfuzzing"
	echo -e "\tjs"
	exit 0
}

function subdomain {
	if [ -z $WILDCARD ]; then
		# Out to: "$WORKDIR/subdomain"
		crtsh "$WORKDIR/domain_lst"
		certspotter "$WORKDIR/domain_lst"
	else
		cp "$WORKDIR/domain_lst" "$WORKDIR/subdomain"
	fi
}

function scanport {
	# Output: "$WORKDIR/ip_lst"
	resolveIP "$WORKDIR/domain_lst"
	# Output: "$WORKDIR/target_ports"
	naabu "$WORKDIR/ip_lst"
}

function techz {
	httprobe "$WORKDIR/target_ports"
	httprobe "$WORKDIR/subdomain"
	httpx "$WORKDIR/target_ports"
	httpx "$WORKDIR/subdomain"
}

function vulnscan {
	mkdir -p "$WORKDIR/vulns"
	nuclei "$WORKDIR/alive"
	# jaeles "$WORKDIR/alive"
	subzy "$WORKDIR/subdomain"
}

function fuzzing {
	mkdir -p "$WORKDIR/fuzz"
	ffuf "$WORKDIR/alive"
}

function js {
	jsfinding "$WORKDIR/alive"
}

# ======================= ARGUMENTS PARSING =======================

MODE="all"	
while getopts 't:m:o:h:s' option; do
	case "${option}" in
		t) HOST="${OPTARG}"; WILDCARD='true' ;;
		s) HOST="${OPTARG}" ;;
		m) MODE="${OPTARG}" ;;
		o) WORKDIR="${OPTARG}" ;;
		h) print_usage ;;
		*) print_usage ;;
	esac
done
if [ -z $1 ]; then print_usage
elif [ -n $1 ] && [ -z $HOST ]; then HOST="$1"	
fi

if [ -z $WORKDIR ] && [ -n $HOST ]; then 
	WORKDIR="$HOME/bb/$HOST.`date '+%Y%m%d'`" 
fi

# ======================= MAIN =======================
pr banner "[+] Target: $HOST"
pr banner "[+] Output: $WORKDIR"
pr banner "[+] Mode: $MODE\n"

mkdir -p "$WORKDIR"
echo $HOST | anew $anew_opt "$WORKDIR/domain_lst"

case $MODE in 
	all)
		subdomain
		scanport
		techz
		vulnscan
		fuzzing
		js
	;;
	subdomain)
		subdomain
	;;
	scanport)
		scanport
	;;
	techz)
		techz
	;;
	vulnscan)
		subdomain
		techz 
		vulnscan
	;;
	fuzzing)
		fuzzing
	;;
	js)
		js
	;;
esac


