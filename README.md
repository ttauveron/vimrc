# vimrc

Configuration Neovim personnelle basee sur `kickstart.nvim`, avec `lazy.nvim`
pour la gestion des plugins.

## Installation

```sh
git clone <url-du-repo> ~/git/vimrc
ln -s ~/git/vimrc ~/.config/nvim
nvim
```

Au premier lancement, `lazy.nvim` installe les plugins automatiquement. Pour
lancer l'installation sans ouvrir l'interface:

```sh
nvim --headless "+Lazy! sync" +qa
```

Si une configuration existe deja dans `~/.config/nvim`, la sauvegarder ou la
supprimer avant de creer le lien symbolique.

## Dependances utiles

- `nvim`: version compatible avec `vim.lsp.config` / `vim.lsp.enable`
  (Neovim 0.11 minimum pour ces API; verification effectuee avec 0.12.6).
- `git`: necessaire a `lazy.nvim`.
- `make`: compile `telescope-fzf-native` si disponible.
- `ripgrep`: utilise par Telescope pour `live_grep`.
- `jq`: utilise par la commande `:JsonFmt`.
- `tofu`: utilise pour le formatage Terraform/OpenTofu.
- `gopls`: installe via Mason pour Go.
- `python3` avec support des environnements virtuels: execution Python et
  installation de `debugpy` via Mason.
- `node` et `npm`: installation et execution de Pyright via Mason.

## Organisation

- `init.lua`: point d'entree; definit les leaders et charge les modules.
- `lua/config/`: bootstrap Lazy, options, raccourcis generaux, evenements et
  detection des types de fichiers.
- `lua/plugins/`: declarations Lazy regroupees par fonction. Chaque plugin
  conserve sa configuration et ses raccourcis dans son bloc `config` ou `opts`.
  Tous les fichiers de ce dossier sont importes automatiquement.
- `lua/custom/`: commandes personnelles (`JsonFmt`, Base64, execution shell,
  ouverture des liens) et macro historique.
- `after/ftplugin/csv.lua`: reglages et raccourcis locaux aux buffers CSV/TSV,
  appliques apres le ftplugin du plugin CSV.
- `syntax/mynotes.vim`: syntaxe Markdown enrichie pour les fichiers `.mynotes`.
- `lazy-lock.json`: versions verrouillees des plugins.

Les modules de plugins sont `completion`, `editor`, `git`, `languages`, `lsp`,
`navigation`, `python`, `treesitter` et `ui`. Le module Python charge le
client DAP, son interface et l'adaptateur Python a l'ouverture d'un fichier
Python. Les anciens exemples Kickstart inactifs ont ete retires.

### Ajouter ou modifier une fonctionnalite

- Plugin: ajouter sa declaration au module de `lua/plugins/` correspondant,
  ou creer un nouveau fichier qui retourne une liste de declarations Lazy.
- Serveur de langage: completer la table `servers` de `lua/plugins/lsp.lua`.
- Reglage propre a un langage: creer `after/ftplugin/<filetype>.lua`, avec
  `vim.opt_local` et des raccourcis limites au buffer.
- Raccourci general: modifier `lua/config/keymaps.lua`; les raccourcis de
  plugins restent avec leur plugin.
- Commande personnelle: ajouter un module dans `lua/custom/` et le charger
  depuis `lua/custom/commands.lua`.

Le bootstrap configure les types de fichiers avant le chargement des plugins.
Les options et raccourcis generaux sont ensuite appliques, comme dans la
configuration d'origine. Les dependances entre plugins sont declarees dans
leurs specifications Lazy; l'ordre alphabetique des fichiers ne sert pas a
ordonner leur chargement.

## Fonctionnalites

- Leader: `<Space>`.
- Recherche et navigation avec Telescope.
- LSP active pour Go (`gopls`), Lua (`lua_ls`) et Python (`pyright`) via Mason.
- Menu Python contextuel avec documentation, breakpoints et debogage visuel.
- Completion avec `nvim-cmp`, LuaSnip et snippets VS Code.
- Treesitter pour Bash, C/C++, Go, JavaScript/TypeScript, Lua, Python, Rust,
  Terraform/HCL et Vim.
- Git avec Fugitive, Rhubarb, `vim-gh-line` et Gitsigns.
- UI: theme Palenight, Lualine, Which Key, Wilder, Oil, Marks, indentation
  guides.
- CSV/TSV: support `csv.vim`, delimiter TSV configure automatiquement,
  commande locale `:TSVPreview`.
- Terraform: `vim-terraform`, `terraform_fmt_on_save`, binaire `tofu`.
- `.mynotes`: type de fichier dedie, syntaxe Markdown reutilisee, highlights
  specifiques pour dates, statuts, channels, pseudos et tickets.

## Raccourcis et commandes utiles

- `<leader>,`: chercher un fichier.
- `<leader><Space>`: chercher dans les buffers ouverts.
- `<leader>/`: chercher dans le buffer courant.
- `<leader>sg`: recherche texte avec `live_grep`.
- `<leader>gf`: chercher dans les fichiers Git.
- `gd`, `gr`, `gI`: definition, references, implementations LSP.
- `<leader>rn`: renommer via LSP.
- `<leader>ca`: code action LSP.
- `<leader>e`: afficher le diagnostic courant.
- `<leader>-`: ouvrir Oil.
- `<leader>hp`: previsualiser le hunk Git courant.
- `[c` / `]c`: hunk Git precedent/suivant.
- `[d` / `]d`: diagnostic precedent/suivant.
- `<leader>zz`: executer la ligne courante comme commande shell et inserer la
  sortie en dessous.
- `:Format`: formater le buffer avec le LSP.
- `:JsonFmt`: formater le buffer JSON avec `jq`.
- `:Base64Encode` / `:Base64Decode`: encoder ou decoder une plage ou selection.
- `\o` en mode visuel: ouvrir les lignes selectionnees comme URLs.
- `<Esc>` en terminal: revenir au mode normal.

## Menu contextuel commun

**Clic droit**, **Espace m**, **Maj-F10** et `:ContextActions` ouvrent le meme
menu flottant avec recherche. Choisir une action avec les fleches et Entree,
ou taper quelques lettres pour filtrer; Esc ferme le menu. Le clic droit cible
le symbole clique, y compris sa colonne. Le menu natif Neovim « Inspect » ne
partage plus ce bouton. Les raccourcis Python existants sont conserves.

Les actions sont regroupees par origine et adaptees au buffer et a l'etat:

- **Code**: documentation, definition, references, renommage, formatage, etc.,
  selon les capacites du serveur LSP attache. Python, Go et Lua utilisent le
  meme fournisseur. Les corrections/refactorisations sont demandees au serveur
  et presentees dans le meme type de menu.
- **Debug**: breakpoints et lancement pour les langages configures; variables,
  Watches, pile et console pour les panneaux DAP. Les commandes de pas a pas et
  d'edition ne sont proposees qu'en pause. Aucun debogueur Go n'est installe par
  ce mecanisme: il apparaitra dans le menu lorsque son adaptateur sera configure.
- **Editor**: enregistrement et diagnostics.
- **Extensions / More buffer actions**: les raccourcis locaux possedant une
  description, annonces par les extensions du buffer.

Les listes utilisant `vim.ui.select` (dont les actions LSP et le choix de
l'interpreteur Python) reutilisent cette interface. Les actions principales
sont une selection utile; le menu ne pretend pas enumerer toutes les fonctions
internes de tous les plugins.

### Brancher une extension

`lua/config/context_menu.lua` gere les points d'entree, la fenetre et la
restauration du contexte. Les fournisseurs dans `lua/config/context_actions/`
fournissent les actions; ils ne creent pas leur propre menu. Il n'y a pas de
nouvelle dependance: la presentation reutilise Telescope.

Une extension peut enregistrer un fournisseur depuis sa configuration:

```lua
require('config.context_menu').register('exemple', {
  priority = 40,
  actions = function(context)
    if context.filetype ~= 'sql' then return {} end
    return {
      {
        id = 'exemple.chemin',
        group = 'Mon extension',
        label = 'Afficher le chemin du fichier',
        run = function(origin)
          vim.notify(vim.api.nvim_buf_get_name(origin.bufnr))
        end,
      },
    }
  end,
})
```

Le contexte contient `bufnr`, `winid`, `filetype` et `cursor` (ligne a partir de
1, colonne en octets a partir de 0). Un fournisseur retourne uniquement les
actions pertinentes; `enabled = false` masque une action. Les identifiants
sont uniques, les priorites croissantes determinent l'ordre; reenregistrer un
fournisseur le remplace, `unregister(id)` le retire. Les fournisseurs sont
reevalues avant execution pour verifier que l'action reste disponible.
L'exemple SQL n'ajoute aucun outil de base de donnees: un vrai fournisseur
appellerait l'API de l'extension installee dans sa fonction `run`.

## Python : documentation et debogage

Ouvrir un fichier `.py`, passer en mode normal et appuyer sur **Espace**.
Le menu Which Key apparait apres 150 ms; choisir **p — Python** pour voir
les actions. Aucun raccourci Python n'est ajoute aux buffers Go ou Lua.
Les controles d'execution restent disponibles dans les panneaux du debogueur.

| Touches | Action |
| --- | --- |
| `Espace p h` | Documentation de la fonction sous le curseur |
| `Espace p b` | Placer / retirer un breakpoint sur la ligne courante |
| `Espace p B` | Definir un breakpoint conditionnel |
| `Espace p r` | Lancer le fichier courant sous debogueur |
| `Espace p a` | Lancer avec des arguments, avec prise en charge des guillemets |
| `Espace p c` | Continuer, ou lancer si aucune session n'est active |
| `Espace p n` | Executer la ligne suivante sans entrer dans les fonctions |
| `Espace p i` | Entrer dans la fonction |
| `Espace p o` | Sortir de la fonction |
| `Espace p e` | Inspecter la variable sous le curseur pendant une pause |
| `Espace p x` | Saisir et evaluer une expression pendant une pause |
| `Espace p u` | Afficher / masquer les panneaux |
| `Espace p l` | Relancer la derniere execution avec ses arguments |
| `Espace p q` | Arreter le programme |
| `Espace p v` | Afficher / choisir l'interpreteur Python du projet |

### Actions dans les panneaux du debogueur

Le menu contextuel commun (clic droit, `Espace m` ou `Maj-F10`) propose les
actions du panneau courant. L'ancien raccourci `Espace p m` ouvre le meme menu.
Les actions qui demandent une pause ne sont affichees que lorsque le programme
est arrete sur un breakpoint. L'action « Edit variable / expression »
demande l'expression (par exemple `test` ou `objet.attribut`) puis sa nouvelle
valeur (`42` ou `"Bonjour"`). Les variables et les Watches sont rafraichis apres
validation. Le menu permet aussi de rafraichir apres une commande dans le REPL;
`Espace p R` reste disponible pour le faire directement, sans avancer le programme.

`K`, `gd`, `gr` et les autres raccourcis LSP habituels restent disponibles.
Le menu Document sous `Espace d` est conserve.

Le lancement avec `Espace p r` est direct, sans notification a valider avec
Entree. Le fichier lance est enregistre silencieusement avant l'execution et la relance. Le repertoire
de travail est la racine du projet (par exemple le dossier contenant
`pyproject.toml` ou `.git`), ou le dossier du script en l'absence de marqueur.

Au demarrage du debogage, les variables, la pile d'appels et les expressions
surveillees apparaissent a gauche; la sortie du programme et la console du
debogueur apparaissent en bas. Utiliser `Entree` pour developper une variable
et `Ctrl-w` suivi d'une direction pour naviguer entre les fenetres.
Dans le panneau Watches, passer en insertion pour ajouter une expression.
La console se positionne au debut des logs lorsqu'on y entre et a la fin de
l'execution. La saisie interactive du programme reste possible en mode terminal.
La sortie reste consultable apres la fin du programme; `Espace p u` permet de
fermer les panneaux. Dans le terminal du programme, `Esc` revient au mode normal
pour retrouver le menu.

### Interpreteur et installation

Pyright et le programme debogue utilisent le meme interpreteur, choisi dans
cet ordre: selection manuelle pour le projet, `VIRTUAL_ENV`, `CONDA_PREFIX`,
environnement local `.venv` / `venv` / `env` / `.env`, puis `python3` ou `python`
du PATH. Les environnements actives inexistants sont ignores.
`Espace p v` permet de choisir un executable ou de revenir a la detection
automatique. Ce choix manuel dure le temps de la session Neovim et met a jour
Pyright et les prochaines executions, y compris la relance.

Pyright est installe automatiquement via Mason. A la premiere ouverture d'un
fichier Python, Mason installe aussi `debugpy` dans un environnement separe:
aucun paquet de debogage n'est ajoute au projet. Attendre la fin de ces
installations avant la premiere utilisation. En cas de probleme, ouvrir
`:Mason` et verifier `pyright` et `debugpy`, ou les installer explicitement avec
`:MasonInstall pyright debugpy`.

Pour essayer le parcours, ouvrir `examples/python/debug_demo.py`, poser un
breakpoint sur la ligne `print(message, details)`, puis choisir `Espace p a`
et saisir `"Ada Lovelace"`. Inspecter `name`, `message` et `details`, avancer
avec `Espace p n`, puis continuer avec `Espace p c`.

### Verification Python

Un test d'integration utilise les vrais Pyright et debugpy, un projet temporaire,
un `.venv` et une dependance installee uniquement dans ce dernier. Il verifie
la documentation locale et celle de la dependance, l'affichage du menu Which Key,
le breakpoint, les arguments, les variables dans les panneaux, le pas a pas,
la reprise, la relance, l'arret et l'isolation des raccourcis par type de fichier.
Il verifie aussi le menu LSP commun en Go, l'ajout/retrait d'un fournisseur,
l'annulation des choix et le ciblage du contexte d'origine.
Les plugins et les paquets Mason doivent deja etre installes; `uv` est requis
pour creer l'environnement temporaire du test.

```sh
nvim --headless -i NONE -u NONE --cmd 'set loadplugins' '+luafile tests/python_ide.lua'
```

Le test d'interface attache un client UI a Neovim et verifie les vrais clics
droits successifs (simples et multiples, appui/relachement, mode insertion),
l'annulation et l'entree clavier commune. Il necessite le module Python `msgpack`:

```sh
python3 tests/context_mouse.py
```


## Maintenance

Mettre a jour les plugins depuis Neovim avec `:Lazy`, ou en ligne de commande:

```sh
nvim --headless "+Lazy! sync" +qa
```

Pour remettre les plugins aux versions du fichier de verrouillage, utiliser
`:Lazy restore`. `:Lazy sync` sert a mettre a jour les plugins et peut modifier
`lazy-lock.json`; aucune mise a jour n'a ete faite pendant la refactorisation.

## Notes sur la refactorisation

La separation en modules conserve les plugins actifs, raccourcis, commandes,
serveurs Go/Lua et automatismes existants. Les corrections ciblees sont:

- `vim-go`: utilisation de `build` au lieu de `run` pour le hook Lazy;
- correction du caractere du signe Git `topdelete`;
- suppression des options dupliquees et de code commente inutilise.

Quelques comportements historiques sont volontairement conserves et isoles:

- `lua/config/telescope_compat.lua` contient le pont de compatibilite entre
  Telescope 0.1.x et Treesitter. Le retirer demande une verification conjointe
  des versions de ces plugins.
- `lua/custom/legacy.lua` initialise le registre `e` avec la macro Terraform
  d'origine a chaque demarrage.
- `lua/custom/links.lua` utilise toujours la commande macOS `open`.
- Le formatage LSP a la sauvegarde conserve sa politique actuelle. Avant
  d'ajouter plusieurs serveurs a un meme langage, il faudra definir quel
  serveur formate et eviter les callbacks multiples lors des rattachements.

### Verification effectuee

La configuration d'origine et la version reorganisee ont ete chargees dans
Neovim en mode headless, avec les installations de parseurs et de serveurs LSP
et le lancement des serveurs desactives pour cette comparaison. Les instantanes
comparent les 40 plugins, 275 raccourcis globaux, commandes, options et reglages
de neuf types de fichiers: Go, Lua, Python, Terraform, tfvars, HCL, notes, CSV et
TSV. Les identifiants internes des scripts Vim sont normalises pour la comparaison.
Les versions des plugins deja installes sont utilisees pour ces controles;
le fichier de verrouillage reste inchange.
