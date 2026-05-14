import json
import os

FILE = "contacts.json"


# ------------------ FILE HELPERS ------------------

def load_contacts():
    if not os.path.exists(FILE):
        return []
    with open(FILE, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return []


def save_contacts(contacts):
    with open(FILE, "w", encoding="utf-8") as f:
        json.dump(contacts, f, indent=4, ensure_ascii=False)


# ------------------ CRUD OPERATIONS ------------------

def ajouter():
    print("\n=== Ajouter un contact ===")

    contact = {
        "name": input("Nom: "),
        "first_name": input("Prénom: "),
        "num": input("Numéro de téléphone: "),
        "adresse": input("Adresse: "),
        "email": input("Email: ")
    }

    contacts = load_contacts()
    contacts.append(contact)
    save_contacts(contacts)

    print("✅ Contact ajouté avec succès!\n")


def modifier():
    print("\n=== Modifier un contact ===")
    num = input("Donner le numéro: ")

    contacts = load_contacts()

    for contact in contacts:
        if contact["num"] == num:
            print("Contact trouvé 👍")

            contact["name"] = input("Nouveau nom: ")
            contact["first_name"] = input("Nouveau prénom: ")
            contact["num"] = input("Nouveau numéro: ")
            contact["adresse"] = input("Nouvelle adresse: ")
            contact["email"] = input("Nouvel email: ")

            save_contacts(contacts)
            print("✅ Contact modifié!\n")
            return

    print("❌ Contact introuvable\n")


def supprimer():
    print("\n=== Supprimer un contact ===")
    num = input("Donner le numéro: ")

    contacts = load_contacts()

    for i, contact in enumerate(contacts):
        if contact["num"] == num:
            print("Contact trouvé:", contact)

            confirm = input("Confirmer suppression (s/n): ")
            if confirm.lower() == "s":
                contacts.pop(i)
                save_contacts(contacts)
                print("🗑️ Contact supprimé!\n")
            else:
                print("Annulé.\n")
            return

    print("❌ Contact introuvable\n")


def afficher_tous():
    print("\n=== Liste des contacts ===")
    contacts = load_contacts()

    if not contacts:
        print("Aucun contact.\n")
        return

    for c in contacts:
        print(c)


def afficher_un():
    print("\n=== Afficher un contact ===")
    num = input("Donner le numéro: ")

    contacts = load_contacts()

    for c in contacts:
        if c["num"] == num:
            print(c)
            return

    print("❌ Contact introuvable\n")


# ------------------ MENU ------------------

def menu():
    while True:
        print("\n############## MENU ################")
        print("1. Ajouter un contact")
        print("2. Modifier un contact")
        print("3. Supprimer un contact")
        print("4. Afficher tous les contacts")
        print("5. Afficher un contact")
        print("0. Quitter")
        print("###################################")

        choice = input("Votre choix: ")

        if choice == "1":
            ajouter()
        elif choice == "2":
            modifier()
        elif choice == "3":
            supprimer()
        elif choice == "4":
            afficher_tous()
        elif choice == "5":
            afficher_un()
        elif choice == "0":
            print("👋 Au revoir!")
            break
        else:
            print("❌ Choix invalide")


# ------------------ START ------------------

menu()
