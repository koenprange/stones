#!/bin/bash
 
function display_help {
	echo "Usage: $0 -n <3> -s <21±2> -r <7>"
	echo ""
	echo "Who left this pile of stones on the table?!?"
	echo "Players take turns with the CPU clearing the table."
	echo "Win the game by taking the last stone!"
	echo ""
	echo "-n:             Maximum nuber of stones you can take each turn. Default: 3."
	echo "-s:              Ininital number of stones on the table. Default: 21 ± 2."
	echo "-r:              Number of rounds. If -n, -s, or both are not set,"
	echo "   they will be determined based on the desired number of rounds. Default: 7."
	echo "-v:              Verbose. Show the computer's estimate of optimal game length.'"
	echo "-h:             Display this help message."
	echo ""
	exit 1
}
 
function init_game {      
	## Set game conditions based on supplied defaults
	if [ -z "$ROUNDS" ]
	then
		ROUNDS=8
	fi

	if [ -z "$MAXGRAB" ]
	then
	if [ -z $STONES ]
	then
		MAXGRAB=3
	else
		let "MAXGRAB = $STONES / $ROUNDS"
	fi
	fi

	if [ -z "$STONES" ]
	then
		DRIFT=$(( $RANDOM % (($MAXGRAB * 2) - 1) ))
		STONES=$(( ($ROUNDS * $MAXGRAB) - $MAXGRAB + $DRIFT + 1 ))
	fi

	## Set some minimum values if needed
	[[ $MAXGRAB -lt 2 ]] && MAXGRAB=2
	[[ $STONES -lt 2 ]] && STONES=2

	## Determine who will start
	let "PLAYERFIRST = $RANDOM % 2"
}
 
function welcome_message {
	echo "*************"
	echo "*S T O N E S*"
	echo "*************"
	echo "There is a pile of $STONES stones on the table."
	echo "Every turn, you HAVE to take at least 1 and at most $MAXGRAB stones."
	echo "The player who clears the table wins!"
	echo "*************"
	echo ""
	echo "***********"
	echo "GAME START!"
	echo "***********"

}
function player {
	echo "*****************************************"
	echo "Your turn! How many stones will you take?"
	echo "*****************************************"

	TURN=0

	# Keep reading the prompt till we have an in range number input.
	while [[ $TURN -lt 1 || $TURN -gt $MAXGRAB ]]
	do
		read -p "(1..$MAXGRAB):" TURN             
		while ! [[ $TURN =~ $NUMBER_RE ]]
		do
			read -p "(1..$MAXGRAB):" TURN              
		done
		echo ""
	done

	# Do the move
	let "STONES = $STONES - $TURN"

	# Check if they won and exit if yes
	if [[ $STONES -lt 1 ]]
	then
		echo "The table is empty! You won!"
		echo "Now get back to work $USER, you lazy bum!"
		echo "Transcript of game and summary of idle time sent to: m.dewinther@amsterdamumc.nl"
		sleep 5
		echo "Nah just kidding... ;-)"
		exit 0
	fi

	# Report and hand over the turn
	[[  $TURN -gt 1 ]] && echo "You take $TURN stones." || echo "You take $TURN stone."
	[[ $STONES -gt 1 ]] && echo "$STONES stones remaining on the table..." || echo "$STONES stone remaining on the table..."
	echo ""
}
 
function comp {
	echo "***********"
	echo "CPU's turn!"
	echo "***********"

	# First check if we can win this round
	if [[ $STONES -gt $MAXGRAB ]]
	then
	   # If not, calculate how many to grab to land on n+1
	   DIFF=$(( STONES % $MAXGRAB ))
	   case $DIFF in
		   0)
			   let "TURN = $MAXGRAB - 1"
			   ;;
		   1)
			   TURN=$MAXGRAB
			   ;;
			*)
			   let "TURN = $DIFF - 1"
			   ;;
	   esac
  
	   # Test if we are on a winning pace and we are on 'n+1' target
	   ROUNDS_TO_WIN=$(( ( STONES - TURN - 1 ) / MAXGRAB ))
	   WIN_PACE=$(( ( ROUNDS_TO_WIN % 2 ) ))
	   ON_TARGET=$(( ( STONES % MAXGRAB ) ))
	   [[ $VERBOSE -eq 1 ]] && echo "CPU Win Pace:  $WIN_PACE"
	   [[ $VERBOSE -eq 1 ]] && echo "CPU On Target: $ON_TARGET"
	   
	   # If on target but not on pace, try to turn the pace by minimising damage
	   [[ $ON_TARGET -eq 1 && $WIN_PACE -eq 0 ]] && TURN=1
	   
	   # If not on target and not on pace, go for broke instead of trying to get on target. IF we have enough time to recover! ELse minimise damage. In between, keep trying to get on target.
	   [[ $ON_TARGET -eq 0 && $WIN_PACE -eq 0 && $ROUNDS_TO_WIN -ge 6 ]] && TURN=$MAXGRAB
	   [[ $ON_TARGET -eq 0 && $WIN_PACE -eq 0 && $ROUNDS_TO_WIN -lt 3 ]] && TURN=1
	   
   
	   [[ $VERBOSE -eq 1 ]] && echo "CPU Clears Table In: $ROUNDS_TO_WIN round(s)."
	   [[ $TURN -gt 1 ]] && echo "CPU takes $TURN stones." || echo "CPU takes $TURN stone."
	else
		# We can win, just grab all to clear the board
		TURN=$MAXGRAB
		[[ $STONES -gt 1 ]] && echo "CPU takes $STONES stones." || echo "CPU takes $STONES stone."
	fi

	# Make the move
	let "STONES = $STONES - $TURN"

	# Check if we won and exit if yes
	if [[ $STONES -lt 1 ]]
	then
		echo "The table is empty! I won!"
		echo "Haha! Better luck next time, $USER..."
		exit 0
	fi
			  
	# Report and hand over the turn
	[[ $STONES -gt 1 ]] && echo "$STONES stones remaining on the table..." || echo "$STONES stone remaining on the table..."
}
 
## Setup
# Parse flags
NUMBER_RE='^[0-9]+$'
while getopts ":n:s:r:vh" opt
do
	case $opt in
		n)
			[[ $OPTARG =~ $NUMBER_RE ]] && MAXGRAB=$OPTARG || echo "WARNING: $OPTARG is not a nubmer. Using default value instead."
			;;
		s)
			[[ $OPTARG =~ $NUMBER_RE ]] && STONES=$OPTARG || echo "WARNING: $OPTARG is not a nubmer. Using default value instead."
			;;
		r)
			[[ $OPTARG =~ $NUMBER_RE ]] && ROUNDS=$OPTARG || echo "WARNING: $OPTARG is not a nubmer. Using default value instead."
			;;
		h)
			display_help
			;;
		v)
			VERBOSE=1
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
	esac
done
 
# Prepare the environment
init_game
welcome_message
 
## Main game loop
while true
do
	if [[ $PLAYERFIRST == 1 ]]     
	then
		player
		comp
	else
		comp
		player
	fi         
done