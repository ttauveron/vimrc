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
`navigation`, `treesitter` et `ui`. Les exemples Kickstart inactifs de formatage
et de debogage ont ete retires; aucun debogueur n'est active a ce stade.

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
- LSP active pour Go (`gopls`) et Lua (`lua_ls`) via Mason.
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
