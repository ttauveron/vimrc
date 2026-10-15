"""Ouvrir ce fichier dans Neovim, puis utiliser le menu Espace p."""

import sys


def greet(name: str) -> str:
    """Construit un message de bienvenue pour la personne indiquee."""
    message = f"Bonjour {name}"
    details = {"name": name, "length": len(name)}
    print(message, details)  # Poser un breakpoint ici avec Espace p b.
    return message


if __name__ == "__main__":
    result = greet(sys.argv[1] if len(sys.argv) > 1 else "Neovim")
    print(f"Resultat : {result}")
