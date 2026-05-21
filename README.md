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

- `nvim`: version recente de Neovim.
- `git`: necessaire a `lazy.nvim`.
- `make`: compile `telescope-fzf-native` si disponible.
- `ripgrep`: utilise par Telescope pour `live_grep`.
- `jq`: utilise par la commande `:JsonFmt`.
- `tofu`: utilise pour le formatage Terraform/OpenTofu.
- `gopls`: installe via Mason pour Go.

## Contenu principal

- `init.lua`: configuration principale, options, plugins, LSP, completion et
  raccourcis.
- `lazy-lock.json`: versions verrouillees des plugins.
- `plugged/mynotes.vim`: support local du type de fichier `.mynotes`.
- `lua/kickstart/plugins/`: modules optionnels herites de kickstart
  (`autoformat`, `debug`), actuellement non charges.

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
- `.mynotes`: type de fichier dedie avec syntaxe Markdown et highlights
  specifiques.

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

Les ajouts de plugins peuvent se faire directement dans `init.lua`. Le dossier
`lua/custom/plugins/` existe aussi, mais son import est commente dans la
configuration actuelle.
