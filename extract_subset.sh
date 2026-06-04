#!/bin/bash

# ==========================================
# Configuration (à adapter selon tes chemins)
# ==========================================
SOURCE_IMAGES="dataset/merged_combined_dataset_foodpacket_8000_plus_synthetic_logos/val/images"   # Dossier contenant tes images originales
SOURCE_LABELS="dataset/merged_combined_dataset_foodpacket_8000_plus_synthetic_logos/val/labels"   # Dossier contenant tes labels .txt originaux
DEST_DIR="dataset_subset"                # Dossier de destination
SAMPLES_PER_CLASS=50                     # Nombre d'images à extraire par classe
NUM_CLASSES=17                           # Tes 17 classes (IDs de 0 à 16)
IMG_EXT=".jpg"                           # Extension de tes images (.jpg, .png...)
# ==========================================

echo "Création de l'arborescence dans $DEST_DIR..."
for i in $(seq 0 $((NUM_CLASSES - 1))); do
    mkdir -p "$DEST_DIR/class_$i/images"
    mkdir -p "$DEST_DIR/class_$i/labels"
done

# Initialisation des compteurs pour chaque classe
declare -A counts
for i in $(seq 0 $((NUM_CLASSES - 1))); do
    counts[$i]=0
done

echo "Extraction en cours..."

# Parcours des fichiers labels
for label_file in "$SOURCE_LABELS"/*.txt; do
    # Extraire le nom du fichier sans l'extension
    filename=$(basename "$label_file")
    image_name="${filename%.txt}$IMG_EXT"

    # Vérifier que l'image correspondante existe bien
    if [ ! -f "$SOURCE_IMAGES/$image_name" ]; then
        continue
    fi

    # Trouver les classes uniques présentes dans ce fichier label
    # On lit le 1er mot (colonne 1) de chaque ligne avec awk
    classes_in_file=$(awk '{print $1}' "$label_file" | sort -u)

    for class_id in $classes_in_file; do
        # Vérifier que l'ID est valide (nombre entier entre 0 et 16)
        if [[ "$class_id" =~ ^[0-9]+$ ]] && [ "$class_id" -lt "$NUM_CLASSES" ]; then
            
            # Si on n'a pas encore atteint le quota pour cette classe
            if [ "${counts[$class_id]}" -lt "$SAMPLES_PER_CLASS" ]; then
                
                # Copier l'image et le label dans l'arborescence de la classe
                cp "$SOURCE_IMAGES/$image_name" "$DEST_DIR/class_$class_id/images/"
                cp "$label_file" "$DEST_DIR/class_$class_id/labels/"
                
                # Incrémenter le compteur
                counts[$class_id]=$((counts[$class_id] + 1))
            fi
        fi
    done

    # Vérification d'arrêt prématuré : a-t-on toutes nos images pour toutes les classes ?
    all_done=true
    for i in $(seq 0 $((NUM_CLASSES - 1))); do
        if [ "${counts[$i]}" -lt "$SAMPLES_PER_CLASS" ]; then
            all_done=false
            break
        fi
    done
    
    if $all_done; then
        echo "Quota de $SAMPLES_PER_CLASS images atteint pour les $NUM_CLASSES classes !"
        break
    fi
done

echo "Extraction terminée avec succès."
echo "Pour vérifier la répartition, tu peux lancer : find $DEST_DIR -type f | wc -l"