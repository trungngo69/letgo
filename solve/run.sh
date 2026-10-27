#!/bin/bash
# usage: run.sh <cfg> <tmo_seconds> <cnf> ; env AT, BENCH(0/1), PUSH(0/1)
C=$1; T=$2; F=$3; S=${C##*-}; N=$(nproc); B=$PWD/bin
mkdir -p o; rm -f o/*
seed() { echo $(( (S*97 + $1*13 + ${RUN_SALT:-0}) % 2000000 + 1 )); }
case $C in
  pal-*)  timeout -s TERM $T $B/palsat -t $N $F $(seed 1) > o/1.txt 2>&1 & ;;
  ypr-*)  i=0; for cb in 380 420 460 520; do i=$((i+1)); timeout -s TERM $T $B/yalsat --probsat --cb=$((cb+S*7)) $F $(seed $i) > o/$i.txt 2>&1 & done ;;
  yal-*)  for i in $(seq 1 $N); do timeout -s TERM $T $B/yalsat $F $(seed $i) > o/$i.txt 2>&1 & done ;;
  prb-*)  i=0; for cb in 4.4 4.8 5.0 5.4; do i=$((i+1)); timeout -s TERM $T $B/probsat -a --fct=1 --cb=$cb $F $(seed $i) > o/$i.txt 2>&1 & done ;;
  ksat-*) for i in $(seq 1 $N); do timeout -s TERM $T $B/kissat --sat --seed=$(seed $i) $F > o/$i.txt 2>&1 & done ;;
  kdef-*) for i in $(seq 1 $N); do timeout -s TERM $T $B/kissat --seed=$(seed $i) $F > o/$i.txt 2>&1 & done ;;
  cad-*)  for i in $(seq 1 $N); do o=""; [ $((i%2)) = 0 ] && o="--sat"; timeout -s TERM $T $B/cadical $o --seed=$(seed $i) $F > o/$i.txt 2>&1 & done ;;
  *) echo "unknown cfg $C"; exit 2 ;;
esac
t0=$(date +%s)
while true; do
  f=$(grep -l "^s SATISFIABLE" o/*.txt 2>/dev/null | head -1)
  if [ -n "$f" ]; then
    grep "^v" $f | tr -d 'v' | tr ' ' '\n' | grep -v '^$' > sol.txt
    if python3 solve/verify.py $F sol.txt; then
      echo "SOLVED cfg=$C file=$f after $(( $(date +%s)-t0 ))s"
      if [ "${PUSH:-1}" = 1 ]; then
        git config user.email bot@users.noreply.github.com; git config user.name bot
        git add -f sol.txt && git commit -qm "sol $AT $C" && git push -q origin HEAD:refs/heads/sol-$AT-$C && echo PUSHED sol-$AT-$C
        [ -n "$GH_TOKEN" ] && gh run cancel $GITHUB_RUN_ID -R $GITHUB_REPOSITORY >/dev/null 2>&1
      fi
      pkill -TERM -x palsat; pkill -TERM -x yalsat; pkill -TERM -x probsat; pkill -TERM -x kissat; pkill -TERM -x cadical
      exit 0
    else echo "VERIFY FAILED $f"; mv $f $f.bad; fi
  fi
  if ! pgrep -x "palsat|yalsat|probsat|kissat|cadical" >/dev/null; then break; fi
  sleep 0.3
done
sleep 1
echo "NOSOLVE cfg=$C after $(( $(date +%s)-t0 ))s"
for f in o/*.txt; do echo "== $f: $(grep -oE 'minimum of [0-9]+|best\([0-9]+\)' $f | tail -2 | tr '\n' ' ')"; done
exit 1
