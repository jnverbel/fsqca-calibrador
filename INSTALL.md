# Installing and opening the fsQCA Calibrator

*🇬🇧 English · [🇪🇸 Español](INSTALAR.md)*

This tool runs **on your own computer**. Your data never leaves it: nothing is uploaded to
the internet, nothing is stored on any server.

You install it once. After that, you open it with a double click.

> **Note on language.** The tool's interface and the report it generates are in Spanish.
> This guide is in English so that a reviewer or a collaborator can install and run it
> without reading Spanish.

---

## Step 1 · Install R

R is the program that does the computation. You install it once and never have to open it:
the tool uses it under the hood.

### On Windows

1. Open <https://cran.r-project.org/bin/windows/base/>
2. Click **Download R for Windows**.
3. Run the downloaded file and accept all the default options.

### On Mac

1. Open <https://cran.r-project.org/bin/macosx/>
2. Download the installer that matches your Mac:
   - **Apple Silicon** if your Mac is an M1, M2, M3 or later.
   - **Intel** if it predates 2020.
   - If you are not sure: Apple menu → *About This Mac*. If it says "Apple chip", it is
     Apple Silicon.
3. Run the installer and accept the defaults.

---

## Step 2 · Open the tool

The folder you received contains two files. Use the one for your system:

- **Windows:** double-click `Ejecutar-en-Windows.bat`
- **Mac:** double-click `Ejecutar-en-Mac.command`

A black window with text will open. **Do not close it**: that is the tool running. After a
few seconds a tab will open by itself in your browser.

**The first run takes several minutes.** It is downloading the computation packages. You
can leave it working and go get a coffee. Subsequent runs start in seconds.

To close the tool, close the black window.

---

## If something does not work

### Windows says the file is not safe

Windows distrusts files downloaded from the internet. Click **More info** and then **Run
anyway**.

### Mac says it cannot open it because the developer is unidentified

**Right-click** on `Ejecutar-en-Mac.command` and choose **Open**. The same warning appears,
but now with an **Open** button. You only have to do this the first time.

### The black window says it cannot find R

R did not get installed, or it was installed after the window was opened. Close the window,
go back to Step 1, then open the file again.

### On Mac, it says it could not install the packages

Macs are sometimes missing the build tools. Open the **Terminal** application (find it with
⌘+Space) and type exactly this line:

```
xcode-select --install
```

Press Enter, accept the installation and wait for it to finish. Then open
`Ejecutar-en-Mac.command` again.

### The browser does not open by itself

Open your browser and type this into the address bar:

```
http://127.0.0.1:7788
```

### Anything else

Take a screenshot of the whole black window and send it to whoever gave you the tool. The
text in that window says what happened.

---

## Worth knowing

**Your data does not travel.** The response file is read on your machine and disappears
from memory when you close the tool. The only thing saved is what you download.

**Save the project file.** At the end of a session, download the `proyecto.json` file. It
holds your anchors, your justifications and the resolution of every alert — all of your
methodological work, not the data. With it you can pick up where you left off and
regenerate the report.

**You see the report inside the tool.** It appears in full in the last step, and you can
download it as HTML to open in a browser or print.

**For the Word version**, send the `proyecto.json` file to whoever gave you the tool and
they will return it as `.docx`, ready for you to copy tables and text into your
dissertation. That file carries your anchors, your justifications and the resolution of
every alert — **it does not carry your data**.
