#!/bin/bash

# get callsign
read player
player=${player//[$'\t\r\n ']}
if [ "$player" == "" ]; then
    player="NOCALL"
fi
printf "Welcome to PACKET Wordle, $player!\n\n"

# display today's high score
url="https://ve1lg.ca/wordle/high.php"
high=$(curl -s $url)
printf "Today's high score is $high\n\n"

# has this player played today or not?
url="https://ve1lg.ca/wordle/played.php?call=$player"
played=$(curl -s $url)
if [[ "$played" == "played" ]]; then
    printf "Sorry, $player, you have already played today's Wordle."
    url="https://ve1lg.ca/wordle/ten.php"
    ten=$(curl -s $url)
    printf "$ten\n\n"
    exit
fi

# load dictionaries and daily word
printf "Loading dictionaries..."
url="https://ve1lg.ca/wordle/dict.txt"
allUrl="https://ve1lg.ca/wordle/allwords.txt"
daily="https://ve1lg.ca/wordle/daily.php"
code=$(echo -n "c66120cc5011014fb6f5f4296b031545e5dccb30" | sha1sum | awk '{print $1}')
words=($(curl -s $url | grep '^\w\w\w\w\w$' | tr '[a-z]' '[A-Z]')) 
allwords=($(curl -s $allUrl | grep '^\w\w\w\w\w$' | tr '[a-z]' '[A-Z]'))
actual=($(curl -s $daily?code=$code))

# display instructions
printf "done\n\nGuess the 5 letter word.\n\nAn asterisk indicates a correct letter in the correct position.\n"
printf "A plus indicates a correct letter in the wrong position.\nA dash indicates an incorrect letter.\n\n"
printf "Enter * to quit the game.\n\nGood luck!\n"

# start starting values
guess_count=1
score=320
max_guess=6
left=ABCDEFGHIJKLMNOPQRSTUVWXYZ

# loop through max_guess turns
while [[ $guess_count -le $max_guess ]]; do
    # get user's guess
    printf "\nCurrent score: $score  ...  Enter your guess ($guess_count / $max_guess): "
    read guess
    guess=${guess//[$'\t\r\n ']}
    printf "\n"

    # does the user want to quit?
    if [[ "$guess" == "*" ]]; then
        printf "Bye\n"
        exit
    fi

    # guess was a word not a command
    guess=$(echo $guess | tr '[a-z]' '[A-Z]')
    if [[ " ${words[*]} " =~ " $guess " ]] || [[ " ${allwords[*]} " =~ " $guess " ]]; then
        # we have a "valid" word found in the two dictionaries
        guess_count=$(( $guess_count + 1 ))
        remaining=""
        for ((i = 0; i < ${#actual}; i++)); do
            if [[ "${actual:$i:1}" != "${guess:$i:1}" ]]; then
                remaining+=${actual:$i:1}
            fi
        done
        for ((i = 0; i < ${#actual}; i++)); do
            if [[ "${actual:$i:1}" != "${guess:$i:1}" ]]; then
                if [[ "$remaining" == *"${guess:$i:1}"* ]]; then
                        color="+" # in it but not there
                        remaining=${remaining/"${guess:$i:1}"/}
                else
                        color="\055" # wrong
                fi
            else
                    color="*" # correct
            fi
	    printf "$color${guess:$i:1} "
	    if [[ "$color" != "\055" ]]; then
                left=${left/${guess:$i:1}/$color${guess:$i:1}}
            else
                left=${left/${guess:$i:1}/}
            fi
        done
        # remove extraneous hint symbols
        left="${left//\+\+\+\+/\+}"
        left="${left//\+\+\+/\+}"
        left="${left//\+\+/\+}"
        left="${left//\*\*\*\*/\*}"
        left="${left//\*\*\*/\*}"       
        left="${left//\*\*/\*}"
        left="${left//\+\*/\*}"
        left="${left//\*\+/\*}"
        printf "     [${left}]\n"
        if [[ $actual == $guess ]]; then
	    printf "\nCongratulations, you guessed $actual correctly! Your score is $score\n"

            # set score in db
            url="https://ve1lg.ca/wordle/score.php?call=$player&score=$score&code=$code"
            $(curl -s $url)

            # display top ten scores
            url="https://ve1lg.ca/wordle/ten.php"
            ten=$(curl -s $url)
            printf "$ten\n\n"

            exit
        fi
        score=$(( $score / 2 ))
    else
        printf "Please enter a valid word with 5 letters!\n";
    fi
done
printf "\nYou lose! The word was  $actual"

# display top ten scores
url="https://ve1lg.ca/wordle/ten.php"
ten=$(curl -s $url)
printf "$ten\n\n"
