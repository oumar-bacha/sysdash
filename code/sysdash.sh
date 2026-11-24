#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [--help]"
  echo "Tableau de bord système : moniteur, logs, audit."
}

# Affiche RAM et swap en Mo (valeurs lues dans /proc/meminfo, en Ko)
mem_info() {
  local total avail swt swf
  total=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
  avail=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
  swt=$(awk '/^SwapTotal/ {print $2}' /proc/meminfo)
  swf=$(awk '/^SwapFree/ {print $2}' /proc/meminfo)
  echo "RAM     : $(( (total - avail) / 1024 )) / $(( total / 1024 )) Mo utilisés"
  echo "Swap    : $(( (swt - swf) / 1024 )) / $(( swt / 1024 )) Mo utilisés"
}

# Pourcentage de CPU utilisé, mesuré sur 1 seconde
cpu_usage() {
  local cpu user nice system idle iowait irq softirq steal _
  read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
  local idle1=$((idle + iowait))
  local total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
  sleep 1
  read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
  local idle2=$((idle + iowait))
  local total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
  local dtotal=$((total2 - total1))
  local didle=$((idle2 - idle1))
  if [[ $dtotal -eq 0 ]]; then
  echo 0
  return
  fi
  echo $(( 100 * (dtotal - didle) / dtotal ))
}

# Affiche les 10 premiers processus. Argument : mem, pid ou nom (critère de tri)
list_processes() {
  local key dir pid
  case $1 in
    pid) key="-k1,1n" ;;
    nom) key="-k2,2" ;;
    *)   key="-k4,4nr" ;;
  esac
  printf "%-7s %-18s %-5s %10s\n" PID NOM ETAT "MEM(Ko)"
  for dir in /proc/[0-9]*; do
    pid=${dir#/proc/}
    [[ -r $dir/status ]] || continue
    awk -v pid="$pid" '
      /^Name:/  {n=$2}
      /^State:/ {s=$2}
      /^VmRSS:/ {m=$2}
      END {print pid, n, s, m+0}' "$dir/status" 2>/dev/null
  done | sort $key | head -10 | awk '{printf "%-7s %-18s %-5s %10s\n", $1, $2, $3, $4}'
}

# Moniteur système : se rafraîchit toutes les ~2 s, touches pour trier ou quitter
monitor() {
  local tri=mem touche l1 l5 l15
  while true; do
    clear
    echo "=== Moniteur système ($(date +%T)) ==="
    echo "CPU     : $(cpu_usage) %"
    read -r l1 l5 l15 _ < /proc/loadavg
    echo "Charge  : $l1 (1 min)  $l5 (5 min)  $l15 (15 min)"
    mem_info
    echo
    list_processes "$tri"
    echo
    echo "[m] tri mémoire  [p] tri PID  [n] tri nom  [q] retour au menu"
    read -rsn1 -t 2 touche
    case $touche in
      q) break ;;
      m) tri=mem ;;
      p) tri=pid ;;
      n) tri=nom ;;
    esac
  done
}


analyse_logs() { echo "[Logs] à faire"; }
audit()        { echo "[Audit] à faire"; }

menu() {
  while true; do
    echo
    echo "1) Moniteur  2) Logs  3) Audit  4) Quitter"
    read -rp "Choix : " c
    case $c in
      1) monitor ;;
      2) analyse_logs ;;
      3) audit ;;
      4) echo "Au revoir"; break ;;
      *) echo "Choix invalide" >&2 ;;
    esac
  done
}

case $1 in
  --help|-h) usage; exit 0 ;;
  "")        menu ;;
  *)         echo "Option inconnue : $1" >&2; usage; exit 1 ;;
esac
