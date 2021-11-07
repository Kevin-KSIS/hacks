#/bin/sh

# ======================= INCLUDES =======================

function pr {
	case $1 in
		banner)
			echo $echo_opt "\n${bgreen}$2 ${reset}"
		;;
		info)
			echo $echo_opt "\n${bblue}${2} ${reset}"
		;;	
		error)
			echo $echo_opt "\n${red}${2} ${reset}"
		;;
		cmd)
			echo $echo_opt "$yellow [$2] $reset [$3] $gray $4 $reset"
		;;
	esac
}
SCRIPTPATH="$(dirname "$0")"
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
	echo $echo_opt "\tdefault: all"
	echo $echo_opt "\tsubdomain"
	echo $echo_opt "\tscanport"
	echo $echo_opt "\ttechz"
	echo $echo_opt "\tvulnscan"
	echo $echo_opt "\tfuzzing"
	echo $echo_opt "\tjs"
	exit 0
}

function subdomain {
	if [ -z $WILDCARD ]; then
		# Out to: "$WORKDIR/subdomain"
		crtsh "$WORKDIR/target_lst"
		certspotter "$WORKDIR/target_lst"
		sublist3r "$WORKDIR/target_lst"
	else
		cp "$WORKDIR/target_lst" "$WORKDIR/subdomain"
	fi
}

function scanport {
	# Output: "$WORKDIR/ip_lst"
	resolveIP "$WORKDIR/target_lst"
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

function test {
	amass_tool "$WORKDIR/target_lst"
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
echo $HOST | anew $anew_opt "$WORKDIR/target_lst"

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
	test)
		test
	;;
esac


