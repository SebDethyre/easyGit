#!/bin/bash
path=$1
# echo "Début du script Bash test.sh"
# echo $path
# Fonction pour remplir l'array options à partir d'un fichier de données
fill_options_from_file() {
    local filename="$1"
    local line_number=1

    # Vider l'array options
    options=()

    # Lire chaque ligne du fichier
    while IFS= read -r line; do
        # Extraire les données entre guillemets de la ligne
        option1=$(echo "$line" | awk -F'"' '{print $2}')
        option2=$(echo "$line" | awk -F'"' '{print $4}')
        option3=$(echo "$line" | awk -F'"' '{print $6}')
        option4=$(echo "$line" | awk -F'"' '{print $8}')
        option5=$(echo "$line" | awk -F'"' '{print $10}')
        option6=$(echo "$line" | awk -F'"' '{print $12}')

        # Ajouter chaque donnée dans une nouvelle colonne de l'array options
        options+=("$line_number" "$option1" "$option2" "$option3" "$option4" "$option5" "$option6")
        ((line_number++))
    done < "$filename"
    # options+=(999 "Option arbitraire 1" "Option arbitraire 2" "Option arbitraire 3" "" "" "")
}


# Fonction pour rechercher et retourner une information spécifique
# Arguments : $1 -> Chaîne de caractères à rechercher
#             $2 -> Position de l'information dans la ligne (1-based index)
find_info() {
    local search_string="$1"
    local position="$2"

    # Vérifier si la position est valide (1-based index)
    if [ "$position" -lt 1 ]; then
        echo "La position doit être un nombre positif supérieur ou égal à 1."
        return 1
    fi

    local found=false

    # Parcourir chaque ligne dans l'array options
    for (( i = 0; i < ${#options[@]}; i += 7 )); do
        local line_number="${options[i]}"
        local line="${options[i+1]}"
        
        # Vérifier si la ligne commence par la chaîne de recherche
        if [[ "$line" == *"$search_string"* ]]; then
            # Récupérer l'élément à la position spécifiée (0-based index)
            local info="${options[i + position]}"
            echo "$info"
            found=true
            break
        fi
    done

    if ! $found; then
        echo "Aucune ligne ne correspond à la chaîne de recherche spécifiée."
        return 1
    fi
}
# Exemple d'utilisation : remplir l'array options à partir d'un fichier
example_file="/home/sdethyre/.venv/omdt/lib/python3.9/site-packages/openmairie/devtools/current_fails.txt"
fill_options_from_file "$example_file"

# Affichage pour déboguer l'array options
# echo "Contenu de l'array options :"
# for (( i = 0; i < ${#options[@]}; i += 7 )); do
#     echo "${options[i+1]} ${options[i+2]} ${options[i+3]} ${options[i+4]} ${options[i+5]} ${options[i+6]}"
# done

# Fonction pour afficher le menu avec Zenity
frm_fail_display() {
    local TMP_SCREEN=""
    local HEADER="RIEN"

    # Construire les arguments pour Zenity
    local zenity_args=(
        --list --width=800 --height=505 --text="<span font-family=\"Arial\">$HEADER</span>"
        --title="Fails"
        --ok-label="✅"
        --cancel-label="❎"
        --column "Test Case" --column "Ligne" --column "Pos" --column "%" --column "Place" --column "Keyword et arguments"
    )

    # Ajouter chaque option du menu
    for (( i = 0; i < ${#options[@]}; i += 7 )); do
        zenity_args+=("${options[i+1]}" "${options[i+2]}" "${options[i+3]}" "${options[i+4]}" "${options[i+5]}" "${options[i+6]}")
    done

    # Afficher le menu et récupérer le choix
    zenity "${zenity_args[@]}" 2>/dev/null
    local response=$?

    # Vérifier si Zenity a été fermé par l'utilisateur
    if [ "$response" != "0" ]; then
        echo "Fenêtre Zenity fermée."
    fi
}

# Fonction pour quitter
_quit() {
    exit 0
}

# Fonction pour parser et traiter le choix du menu
frm_fail_display_parser() {
    local choice="$1"
    line=$(find_info "$choice" "2")
    line_pos=$(find_info "$choice" "3")
    line_pos=$(($line_pos + 1))
    kw_args=$(find_info "$choice" "6")
    code -g $path:$line:$line_pos
    echo "done"
}

# Fonction principale pour exécuter le menu de manière récursive
function_fail_display() {
    local quit="0"
    while [ "$quit" != "1" ]; do
        local menuchoice=$(frm_fail_display)
        local response=$?

        # Vérifier si la boîte de dialogue a été fermée
        if [ "$response" != "0" ]; then
            echo "Boîte de dialogue fermée."
            break
        fi

        frm_fail_display_parser "${menuchoice}"
    done
}

# Démarrer l'exécution du script
function_fail_display
exit 0
