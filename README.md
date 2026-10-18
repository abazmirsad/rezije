# Režije 📊

Mobilna aplikacija (Android + iOS) za praćenje režijskih troškova — struja, voda, plin,
internet, komunalije i ostalo. Svi podaci se čuvaju **lokalno na uređaju** (ništa ne ide
na internet). Aplikacija ima moderan izgled i grafičke prikaze potrošnje.

> Napravljeno u **Flutteru** (jedan kod radi i na Androidu i na iOS-u).

---

## Šta aplikacija radi (trenutna verzija - MVP)

- ➕ Ručni unos računa (kategorija, provajder, iznos, datumi, status plaćanja)
- 📊 **Dashboard** s grafovima:
  - ukupna potrošnja po mjesecima (stupčasti graf, zadnjih 6 mjeseci)
  - podjela troškova po kategorijama (kružni graf)
  - kartice sažetka: ukupno ovaj mjesec, neplaćeno, koliko računa kasni
- 📋 Lista svih računa s filterima (svi / neplaćeni / plaćeni)
- ✅ Označavanje računa kao plaćenog jednim dodirom
- ✏️ Uređivanje i brisanje (povlačenjem ulijevo)
- 🇧🇦 Kompletno na bosanskom jeziku, valuta KM

Pri prvom pokretanju aplikacija ubaci nekoliko **primjera računa** da grafovi odmah imaju
šta prikazati. Njih možeš slobodno obrisati.

---

## ⚙️ Instalacija alata (jednokratno)

Na računaru trenutno **nema Fluttera**. Treba ga instalirati da bi aplikaciju pokrenuo.
Prati korake redom.

### 1. Instaliraj Flutter SDK
1. Idi na https://docs.flutter.dev/get-started/install/windows
2. Preuzmi Flutter SDK (zip) i raspakuj ga npr. u `C:\flutter`
   (izbjegavaj foldere s razmakom u imenu i `C:\Program Files`).
3. Dodaj `C:\flutter\bin` u sistemsku **Path** varijablu:
   - Windows pretraga → "Edit the system environment variables"
   - "Environment Variables..." → pod *User variables* izaberi **Path** → *Edit* → *New*
   - zalijepi `C:\flutter\bin` → OK
4. Otvori **novi** PowerShell prozor i provjeri:
   ```powershell
   flutter --version
   ```

### 2. Instaliraj Android Studio (za Android SDK i emulator)
1. Preuzmi s https://developer.android.com/studio i instaliraj.
2. Pri prvom pokretanju proći će kroz "Setup Wizard" i instalirati Android SDK.
3. U Android Studiju otvori **More Actions → SDK Manager** i provjeri da su instalirani:
   - Android SDK Platform (najnoviji)
   - Android SDK Command-line Tools
   - Android SDK Build-Tools
4. Prihvati licence:
   ```powershell
   flutter doctor --android-licenses
   ```

### 3. Provjeri da je sve spremno
```powershell
flutter doctor
```
Cilj je da stavke za Flutter i Android imaju ✓ (zeleno). Git i ostalo `flutter doctor`
će ti reći ako fali.

> **Napomena:** Java (OpenJDK) je već instalirana na ovom računaru. ✓

---

## ▶️ Pokretanje aplikacije

Iz foldera projekta (`Rezije`):

```powershell
# 1. Preuzmi sve pakete (dependencies)
flutter pub get

# 2a. Pokreni na Android emulatoru ili spojenom telefonu
flutter run
```

### Pokretanje na fizičkom Android telefonu
1. Na telefonu uključi **Developer options** i **USB debugging**
   (Settings → About phone → 7x tapni "Build number", pa Settings → Developer options).
2. Spoji telefon USB kablom i dozvoli debugging.
3. Provjeri da ga Flutter vidi:
   ```powershell
   flutter devices
   ```
4. Pokreni:
   ```powershell
   flutter run
   ```

### Pravljenje APK-a za instalaciju na telefon
```powershell
flutter build apk --release
```
Gotov APK se nalazi u `build\app\outputs\flutter-apk\app-release.apk` — prebaci ga na
telefon i instaliraj.

### iOS
Za iOS je potreban **Mac** s Xcode-om (Apple ograničenje). Kod je spreman, build se radi
na Macu komandom `flutter build ios`.

---

## ☁️ Build u oblaku bez instaliranja Fluttera (GitHub Actions)

Ako ne želiš lokalno instalirati Flutter i Android SDK, APK možeš napraviti **u oblaku**.
U projektu je već pripremljen workflow `.github/workflows/build.yml` koji na GitHub-ovim
serverima automatski:
1. instalira Flutter i Javu,
2. generiše Android projekat (`flutter create`),
3. napravi `app-release.apk`,
4. okači ga za download.

Tebi lokalno treba samo **Git** (da gurneš kod na GitHub). Sve ostalo radi GitHub.

### Korak 1 — Instaliraj Git (jednokratno)
1. Preuzmi s https://git-scm.com/download/win i instaliraj (sve ostavi na "Next").
2. Otvori **novi** PowerShell i provjeri:
   ```powershell
   git --version
   ```

### Korak 2 — Napravi prazan repozitorij na GitHub-u
1. Prijavi se na https://github.com (nalog: abaz.mirsad@gmail.com).
2. Klikni **New repository** (zeleno dugme ili ikona +).
3. Ime npr. `rezije`, ostavi **prazan** (bez README/gitignore), klikni **Create repository**.
4. Zapamti URL koji dobiješ, npr. `https://github.com/TVOJ-USERNAME/rezije.git`.

### Korak 3 — Gurni kod na GitHub (iz foldera projekta)
Pokreni ove komande redom u PowerShell-u, u folderu `Rezije`.
Prvi put Git će tražiti da se identifikuješ (zamijeni svojim podacima):

```powershell
git config --global user.email "abaz.mirsad@gmail.com"
git config --global user.name "Tvoje Ime"

git init
git branch -M main
git add .
git commit -m "Prva verzija aplikacije Rezije"

# Zamijeni TVOJ-USERNAME svojim GitHub korisničkim imenom:
git remote add origin https://github.com/TVOJ-USERNAME/rezije.git
git push -u origin main
```

> Pri `git push` otvoriće se prozor za prijavu na GitHub (preko browsera).
> Prijaviš se jednom i to je to.

### Korak 4 — Preuzmi gotov APK
1. Na GitHub-u otvori svoj repo → tab **Actions**.
2. Build (**"Build Android APK"**) kreće automatski nakon push-a. Traje par minuta.
3. Kad završi (zeleni ✓), otvori taj build i na dnu pod **Artifacts** skini `rezije-apk`.
4. Raspakuj zip, prebaci `app-release.apk` na telefon i instaliraj
   (možda treba dozvoliti "instalacija iz nepoznatih izvora").

> Svaki sljedeći put kad promijeniš kod: `git add .`, `git commit -m "opis"`, `git push` —
> i novi APK se sam napravi.

---

## 📁 Struktura projekta

```
lib/
├── main.dart                     # Ulazna tačka, tema, lokalizacija
├── models/
│   ├── racun.dart                # Model računa (+ spremanje u bazu)
│   └── kategorija.dart           # Kategorije: naziv, ikonica, boja
├── data/
│   └── baza_pomocnik.dart        # Lokalna SQLite baza (CRUD)
├── providers/
│   └── rezije_provider.dart      # Stanje aplikacije + statistike za grafove
├── tema/
│   └── app_tema.dart             # Boje, fontovi, Material 3 tema
├── util/
│   └── format.dart               # Formatiranje novca i datuma (KM, bs)
├── widgeti/
│   ├── pie_graf_kategorije.dart  # Kružni graf po kategorijama
│   └── bar_graf_mjeseci.dart     # Stupčasti graf po mjesecima
└── ekrani/
    ├── glavni_ekran.dart         # Donja navigacija + dugme za dodavanje
    ├── dashboard_ekran.dart      # Pregled s grafovima
    ├── lista_racuna_ekran.dart   # Lista računa s filterima
    └── forma_racun_ekran.dart    # Dodavanje / uređivanje računa
```

---

## ⚠️ Važna napomena o verziji Fluttera

Kod koristi `Color.withValues(...)` i `CardThemeData` koji zahtijevaju
**Flutter 3.27 ili noviji**. Kad instaliraš Flutter, dobićeš najnoviju verziju pa je
sve u redu. Ako koristiš stariju verziju, pokreni `flutter upgrade`.

---

## 🔜 Sljedeće faze (dogovoreno, nije još implementirano)

Ovo je **MVP** (osnovna radna verzija). Plan za dalje:

### Faza 2 — Automatsko čitanje računa iz Gmaila
Umjesto ručnog unosa, aplikacija bi preko **Gmail API-ja** (OAuth 2.0 prijava)
skenirala mailove, prepoznala račune (npr. PDF priloge) i automatski izvukla iznos i
rok plaćanja. Ovo je siguran i dopušten način (Google-ov službeni API) i realno najbolji
izvor automatskih podataka.

### Faza 3 (opcionalno) — Status plaćanja preko banke
Preko licenciranog Open Banking / PSD2 agregatora moglo bi se vidjeti da je račun plaćen
sa bankovnog računa. Zahtijeva vanjski servis i više podešavanja.

> Direktno povlačenje s portala pojedinih firmi (HEP, Vodovod, telekomi...) nije pouzdano
> jer rijetke imaju javni API, pa fokus ide na Gmail kao glavni automatski izvor.

---

## ❓ Česti problemi

- **`flutter` nije prepoznata komanda** → nisi dodao `C:\flutter\bin` u Path ili nisi
  otvorio novi terminal nakon izmjene.
- **Nema uređaja (`flutter devices` prazan)** → pokreni emulator iz Android Studija
  (Device Manager) ili spoji telefon s uključenim USB debuggingom.
- **Greške oko Android licenci** → pokreni `flutter doctor --android-licenses` i prihvati sve.
```
