#!/usr/bin/env bash

usage() {
  echo "Usage: $0 [--help]"
  echo "Tableau de bord système : moniteur, logs, audit."
}

monitor()      { echo "[Moniteur] à faire"; }
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
