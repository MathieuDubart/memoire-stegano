//
//  README.md
//  StegApp
//
//  Created by Mathieu Dubart on 28/12/2025.
//

# SteganoDemo — Documentation (Module Texte : chiffrement + message “cover”)

Cette documentation décrit la partie **Texte** de l’application (prototype), en particulier :
- la **gestion de la clé** (clé partagée/importable),
- le **chiffrement/déchiffrement** sous forme de *frame* binaire,
- la génération d’un **message sémantique** (cover text) contenant un identifiant `(ticket/code/note: …)`.

> Objectif du prototype : fournir une démo technique fiable et simple à comprendre.
> Le module vise une **robustesse au copier/coller** et une UX fluide, plus qu’une solution finalisée “production”.

---

## 1. Concepts et termes

### 1.1 Clé de session (clé partagée)
- Une **clé symétrique** (256 bits) est utilisée pour chiffrer et déchiffrer les messages.
- Cette clé est **stockée localement** (Keychain) et peut être :
- **générée** dans l’app,
- **exportée** sous forme de chaîne Base32,
- **importée** depuis un autre appareil (coller la Base32).

Cette séparation clé / message permet :
- de partager le **message** publiquement (ou dans un canal quelconque),
- de partager la **clé** séparément (ex. “code de session” entre personnes autorisées),
- de rendre le payload inutilisable sans la clé.

### 1.2 Frame (format de transport)
Le message chiffré n’est pas directement affiché en binaire : il est encapsulé dans une **frame** (un format stable) afin que l’app puisse :
- reconnaître un payload valide,
- extraire le ciphertext sans ambiguïté,
- évoluer de manière versionnée.

La frame est ensuite encodée en :
- **Base64** (format brut) avec un préfixe type `STGFRAME1:` ; ou
- **Base64URL** dans le message “cover” (token).

### 1.3 Cover text (message sémantique)
Le “cover text” est une phrase lisible qui semble normale pour un humain, à laquelle on ajoute un identifiant de type :

- style **Tech** : `(ticket: <token>)` (ou `build`, `case`, etc.)
- style **Neutre** : `(code: <token>)` (ou `id`, etc.)
- style **Poétique** : `(note: <token>)` (ou `vers`, etc.)

Le **token** est la frame encodée en Base64URL.

---

## 2. Architecture (vue d’ensemble)

### 2.1 Composants principaux
- **`SessionKeyStore`**
Gestion clé : génération, sauvegarde Keychain, export/import Base32.

- **`CryptoService`**
Fournit :
- `encryptFrame(plaintext:) -> Data`
- `decryptFrame(_:) -> String`

- **`FrameCodec`**
Encode et décode le format binaire versionné :
- `packV2(cipherCombined:) -> Data`
- `unpackV2(_:) -> Data`
- `looksLikeFrame(_:) -> Bool`

- **`CoverTextCodec`**
Transforme une frame en message sémantique (et inversement) :
- `encode(frame:style:) -> String`
- `decode(coverText:) -> Data`

- **`TextCryptoView`**
Écran SwiftUI qui orchestre :
- choix du mode (Chiffrer/Déchiffrer),
- choix du format de sortie (Base64 ou Message cover),
- génération/import/export de clé,
- copier/coller.

---

## 3. Gestion de la clé (SessionKeyStore)

### 3.1 Génération
- L’app génère 32 octets (256 bits) via un générateur cryptographiquement sûr (`SecRandomCopyBytes`).
- La clé est stockée dans le **Keychain**.

### 3.2 Stockage Keychain
- La clé est persistée localement afin que l’utilisateur n’ait pas à la ressaisir à chaque lancement.
- Pour une démo, l’accessibilité typique est du type :
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (clé liée à l’appareil).

### 3.3 Export (Base32)
- La clé (32 octets) est encodée en **Base32** pour être :
- copiable facilement,
- lisible,
- moins fragile que du Base64 (pas de `+ / =`).

### 3.4 Import
- L’utilisateur colle une chaîne Base32.
- L’app la décode et vérifie qu’elle fait **exactement 32 octets**.
- Si validation OK, elle devient la clé active en Keychain.

### 3.5 UX recommandée
- Séparer dans l’UI :
- “Copier la clé” (Base32)
- “Importer la clé”
- Afficher un état clair : “Clé active disponible / Aucune clé”.

---

## 4. Chiffrement et frame

### 4.1 Algorithme de chiffrement
Le module utilise un chiffrement authentifié moderne :
- **ChaCha20-Poly1305** (`CryptoKit` / `ChaChaPoly`)

Propriétés :
- Confidentialité du contenu
- Intégrité/authenticité du ciphertext (un token altéré ne déchiffre pas)

### 4.2 Construction de la frame (v2)
Le ciphertext est encapsulé dans une frame binaire versionnée.

**Magic + version**
- Magic = `"SGF1"` (4 octets)
- Version = `2` (1 octet)

**Longueur + contenu**
- `cipherLen` (UInt32 big-endian)
- `cipherCombined` (octets), correspondant à `ChaChaPoly.SealedBox.combined`

**Layout v2**
[4 bytes] "SGF1"
[1 byte ] version = 2
[4 bytes] cipherLen (UInt32 BE)
[n bytes] cipherCombined

### 4.3 Validation frame
Avant de tenter un déchiffrement, l’app appelle :
- `FrameCodec.looksLikeFrame(data)`
pour éviter d’interpréter n’importe quel blob comme une frame.

---

## 5. Formats de sortie

### 5.1 Sortie “Base64”
Usage : debug, vérification rapide, format brut.

- L’app produit :

STGFRAME1:<base64(frame)>

- Au déchiffrement, l’app cherche `STGFRAME1:` puis décode la Base64.

Avantage :
- Très simple
- Pratique en test

Inconvénient :
- Peu “humain”, visuellement suspect

### 5.2 Sortie “Message cover” (phrase + label + token)
Usage : démonstration “humaine” (message plausible) + robustesse.

- L’app produit une phrase sémantique (selon style) + suffixe :
- Tech : `(ticket: <token>)`
- Neutre : `(code: <token>)`
- Poétique : `(note: <token>)`

Le token est :
- `Base64URL(frame)` (Base64 standard avec :
                        - `+` → `-`
                      - `/` → `_`
                      - sans `=`)

Exemple :

Je reproduis le bug, je patch, puis je te ping. (ticket: K2m9-abc_DEF123...)


---

## 6. Décodage du message cover (CoverTextCodec)

### 6.1 Principe
Le décodage suit deux étapes :

1. **Extraction du token** via une regex stable :
- labels acceptés : `ticket|build|case|code|id|note|vers`
- forme : `<label>: <token>`

2. **Décodage Base64URL** du token vers `Data` :
- remplacement `-`→`+`, `_`→`/`
- ajout du padding `=` si nécessaire
- `Data(base64Encoded:)`

3. **Validation frame** :
- `FrameCodec.looksLikeFrame(data)`

4. **Déchiffrement** :
- `CryptoService.decryptFrame(data)`

### 6.2 Pourquoi Base64URL ?
- Résiste mieux aux canaux texte (messageries, réseaux)
- Évite les caractères problématiques (`+`, `/`, `=`)

---

## 7. Flux utilisateur (TextCryptoView)

### 7.1 Chiffrer
1. L’utilisateur saisit un texte clair.
2. Il vérifie qu’une **clé** est disponible (générée ou importée).
3. Il choisit :
- Sortie Base64, ou
- Message cover + style (Tech/Neutre/Poétique)
4. Il clique **Chiffrer**.
5. Il copie le résultat (bouton Copier).

### 7.2 Déchiffrer
1. L’utilisateur colle un message :
- soit une frame `STGFRAME1:...`
- soit un message cover contenant `(ticket/code/note: <token>)`
2. Il clique **Déchiffrer**.
3. Si la **clé** correspond à celle utilisée pour chiffrer, le texte clair est affiché.

---

## 8. Robustesse : règles et bonnes pratiques

### 8.1 Désactivation autocorrect / capitalisation
Sur les champs de saisie/copie (TextEditor / TextField), appliquer :
```swift
    .textInputAutocapitalization(.never)
    .autocorrectionDisabled(true)
```

But : éviter que le système modifie le token.

### 8.2 Validation avant déchiffrement

Toujours valider que Data ressemble à une frame :

évite des erreurs “frame illisible” sur des entrées invalides,

permet des messages d’erreur plus clairs.

### 8.3 Messages d’erreur recommandés

“Aucune clé active. Génère ou importe une clé.”

“Entrée invalide. Colle une frame STGFRAME1… ou un message généré par l’app.”

“Déchiffrement impossible (mauvaise clé ou message altéré).”

## 9. Sécurité : positionnement prototype
### 9.1 Ce que ce prototype garantit

Confidentialité du contenu si la clé reste privée

Intégrité du message chiffré (ChaChaPoly détecte les altérations)

### 9.2 Limites assumées (prototype)

Partage de clé : repose sur le canal choisi (à cadrer dans la démo).

Gestion multi-device : import/export manuel dans la version démo.

Le “cover text” n’est pas une sécurité : c’est un habillage.

### 9.3 Évolutions possibles

Rotation de clé par session (clé éphémère)

Synchronisation de clés (iCloud Keychain / compte)

Support images/vidéos : même frame, payload = binaire (PNG/JPEG/MP4)

## 10. Annexe : exemple de démo
### 10.1 Partage de la clé (une fois)

Message (canal privé ou groupe de démo) :

Code de session (démo) : ABCD EFGH IJKL ...

### 10.2 Partage de messages (public)

Message cover :

Je reproduis le bug, je patch, puis je te ping. (ticket: K2m9-abc_DEF123...)

### 10.3 Déchiffrement

Importer/coller le “code de session” dans l’app

Coller le message cover

Déchiffrer

## 11. Références techniques (implémentation)

CryptoKit — ChaChaPoly

Security — SecRandomCopyBytes, Keychain (SecItemAdd, SecItemCopyMatching, SecItemUpdate)

Encodages :

Base32 (clé export/import)

Base64URL (token dans le message cover)

## Extension hypothétique : Images et vidéos (prototype)

Cette section propose une extrapolation du fonctionnement actuel (texte) vers des contenus **binaires** (images, vidéos), en conservant la même logique :
- une **clé de session** (import/export),
- une **frame** versionnée contenant un payload chiffré,
- un **message cover** (phrase sémantique + identifiant `(ticket/code/note: …)`),
- une intégration UX via **partage** depuis une app tierce.

> Hypothèse de conception : l’objectif est une **démo technique**. On vise donc un pipeline simple, robuste, et explicable, pas une optimisation maximale.

---

### 1) Principe général (commun texte / image / vidéo)

Dans la version “média”, on ne chiffre plus une chaîne de caractères mais un **flux binaire**.

**Entrées possibles**
- Image : JPEG / PNG / HEIC (selon support iOS)
- Vidéo : MP4 / MOV (H.264/HEVC), etc.

**Sorties possibles**
1. **“Frame brute”** (Base64) : utile en debug / démo interne.
2. **“Cover text”** : phrase sémantique + token (identifiant), pour copier/coller.
3. **Fichier exporté** : un `.stg` (ou autre extension) contenant directement la frame, pour éviter la taille d’un token (recommandé pour vidéo).

---

### 2) Frame v2 : ajout d’un en-tête “mimetype + meta”

Pour les médias, la frame doit embarquer des métadonnées minimales permettant de reconstituer le fichier.

#### 2.1 Champs recommandés
- **magic** : `SGF1`
- **version** : `2` (ou `3` si l’on introduit un nouveau layout)
- **payloadType** : `text | image | video` (1 octet ou enum)
- **mimeType** : ex. `image/jpeg`, `video/mp4` (string courte)
- **fileNameHint** (optionnel) : ex. `IMG_1234.jpg`
- **cipherLen** + **cipherCombined**

#### 2.2 Exemple de layout (v3 hypothétique)

[4] magic "SGF1"
[1] version = 3
[1] payloadType (0=text,1=image,2=video)
[2] mimeLen (UInt16 BE)
[n] mimeType bytes (UTF-8)
[2] nameLen (UInt16 BE) (optionnel, 0 si absent)
[n] fileNameHint bytes (UTF-8) (optionnel)
[4] cipherLen (UInt32 BE)
[n] cipherCombined bytes


**Pourquoi ?**
- `mimeType` permet de reconstruire proprement un fichier au déchiffrement.
- `payloadType` permet d’orienter l’UI (aperçu image vs lecteur vidéo).
- `fileNameHint` améliore l’expérience d’export (partage système, sauvegarde).

---

### 3) Chiffrement (média)

Le chiffrement reste identique :
- clé symétrique **active** (SessionKeyStore / Keychain)
- `ChaChaPoly.seal(data, using: key)`
- stockage dans `cipherCombined`

**Entrée binaire**
- Image : `Data` du fichier original (ou une version recompressée pour démo)
- Vidéo : `Data` de l’asset exporté (ou un fichier temporaire)

**Remarque démo**
- Pour image : chiffrer la `Data` brute fonctionne immédiatement.
- Pour vidéo : chiffrer la `Data` brute fonctionne, mais peut être lourd (taille). Pour une démo, on limite la durée/résolution.

---

### 4) Format “cover text” : faisabilité selon le média

Le cover text fonctionne très bien pour du texte car le token est court.

#### 4.1 Images
- Une image compressée (JPEG) peut rester “raisonnable” (quelques centaines de Ko).
- Un token Base64URL d’une frame de 300 Ko devient très long (≈ 400 Ko en base64) : impraticable à copier/coller.

**Conclusion (image)**
- Le cover text est pertinent pour :
- mini-images, icônes, captures très compressées,
- ou seulement une démo “preuve de concept”.
- Pour une démo réaliste, privilégier un **fichier .stg** partageable plutôt qu’un token inline.

#### 4.2 Vidéos
- Token inline quasi impossible (taille).
- Il faut un **fichier transport** (attachment), ou un stockage/URL.

**Conclusion (vidéo)**
- Le cover text devient plutôt un **message d’accompagnement** + identifiant (non pas la frame entière), sauf si on accepte de transporter la frame comme fichier.

---

### 5) Deux stratégies de transport pour images/vidéos

#### Stratégie A — “Frame en fichier” (recommandée démo)
- Le résultat du chiffrement est un fichier binaire : `export.stg`
- L’app partage ce fichier via iOS Share Sheet
- Le destinataire ouvre le fichier dans l’app (Open In…)

**Avantages**
- Robuste
- Fonctionne avec de gros médias (vidéo)
- UX iOS cohérente

**Inconvénients**
- Moins “magique” que le copier/coller d’un texte

#### Stratégie B — “Token inline” (réservée à petites images)
- La frame est Base64URL directement dans le message cover
- Copie/colle puis déchiffre

**Avantages**
- Simple à expliquer
- Tout passe par texte

**Inconvénients**
- Taille rapidement ingérable

---

### 6) UX iOS : flux “Partager vers l’app”

#### 6.1 Entrée depuis une app tierce
- L’utilisateur, depuis Photos / Safari / Réseaux sociaux, utilise **Partager…**
- Sélectionne l’app SteganoDemo (Share Extension ou “Open In” via UIDocumentInteraction)
- L’app récupère :
- une `UIImage` ou une URL de fichier (image)
- une URL vidéo (asset)

#### 6.2 Écran “MediaCryptoView”
Hypothèse d’écran similaire à TextCryptoView :
- Choix : **Chiffrer / Déchiffrer**
- Bloc clé : génération / import / export
- Bloc contenu :
- aperçu image ou vidéo
- bouton “Chiffrer”
- Sortie :
- fichier `.stg` à partager
- ou message cover (si activé et si taille compatible)

---

### 7) Déchiffrement et restitution

#### 7.1 Déchiffrement
- L’app reçoit :
- soit un fichier `.stg`
- soit un token (si mode inline)

Étapes :
1. lire la frame (Data)
2. valider magic/version
3. extraire `mimeType` + `cipherCombined`
4. déchiffrer avec clé active
5. reconstruire le binaire original

#### 7.2 Restitution UI
- Image :
- `UIImage(data: decryptedData)` et affichage preview
- export vers Photos ou partage
- Vidéo :
- écrire `decryptedData` dans un fichier temporaire `.mp4/.mov`
- lecture via `AVPlayer`
- export/partage

---

### 8) Contraintes et limites (à mentionner explicitement)

- **Taille** : le token inline n’est pas viable pour la vidéo et rarement viable pour les images.
- **Performance** : chiffrement/déchiffrement sur gros fichiers peut être lent et consommateur mémoire.
- Pour une démo : limiter la taille et préférer un traitement fichier (streaming) plus tard.
- **Stockage temporaire** : la vidéo nécessite quasi toujours un fichier temporaire sur disque.
- **Compatibilité** : certains formats (HEIC/HEVC) peuvent nécessiter une conversion/export.
- **Sécurité** : la confidentialité dépend du secret de clé. Le cover text n’est pas un mécanisme de sécurité.

---

### 9) Pistes d’évolution “production” (optionnel)

- **Streaming / chunking** : chiffrer par blocs pour éviter de charger tout en mémoire.
- **Compression contrôlée** : recompression JPEG ou transcodage vidéo pour réduire le poids (mode “démo”).
- **Manifest + payload externe** : message cover contient un identifiant, et le payload est un fichier/URL.
- **Key sync** : synchronisation de clé (iCloud / compte) pour multi-device (hors scope démo).

---

Voice chat ended

