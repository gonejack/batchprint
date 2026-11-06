<!--suppress HtmlDeprecatedAttribute -->
<p align="center">
  <img src="Resources/AppIcon.png" width="144" height="144" alt="BatchPrint app icon">
</p>

<h1 align="center">BatchPrint</h1>

<p align="center">
  A small native macOS utility for batch printing: drop in a set of files, choose a printer and print options, review everything once, and send it all to the print queue as a single job.
</p>

<p align="center">
  <a href="https://github.com/gonejack/batchprint/releases/latest"><img src="https://img.shields.io/github/v/release/gonejack/batchprint?style=flat-square" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?style=flat-square&amp;logo=apple" alt="macOS 13 or later">
  <img src="https://img.shields.io/badge/Universal-Intel%20%7C%20Apple%20Silicon-blue?style=flat-square" alt="Universal: Intel and Apple Silicon">
</p>

## Features

- Drag and drop multiple files, or click to choose them; unsupported or unreadable files are filtered out with a notice
- Supports PDF, common images (PNG, JPEG, TIFF, HEIC, GIF, BMP, WebP), plain text (TXT, MD, CSV, LOG), and RTF
- Choose the printer, single- or double-sided printing (long-edge binding), color or grayscale, and paper size
- Automatically shows the confirmation sheet after the first batch of files is added, with files, page count, and settings
- The drop area collapses once files are added, leaving the file list available for more drops
- Merges every file into one PDF at the selected paper size, then submits it as one print job
- Grayscale mode prints everything in black and white
- Opens files directly from Finder's "Open With" menu
- Compact neutral-gray interface that follows the system light/dark appearance
- English and Simplified Chinese interface, following the system language

## Download and install

1. Open the [latest release](https://github.com/gonejack/batchprint/releases/latest).
2. Download the `.zip` file (for example, `BatchPrint-1.0.1.zip`).
3. Unzip it, then drag `BatchPrint.app` into your **Applications** folder.
4. Open BatchPrint from Applications. If macOS shows a security warning, see the next section.

## If macOS blocks the app

BatchPrint is distributed outside the App Store, so macOS may show a warning the first time you open it. The warning may say the app is from an unidentified developer, cannot be verified, or is damaged. This is expected.

The exact steps depend on your macOS version. After allowing the app once, you can open it normally.

### Option 1: Use Terminal (recommended)

If you are comfortable using Terminal, this is the quickest way to clear the warning:

```sh
xattr -dr com.apple.quarantine /path/to/BatchPrint.app
```

Replace the path if the app is somewhere else, then open the app normally.

> If macOS says the app is damaged, this is usually the quickest fix.

### Option 2: Allow in System Settings

1. Try to open BatchPrint. When the warning appears, click **Done** or **OK**.
2. Open **System Settings › Privacy & Security**.
3. Scroll down to **Security**. Next to the message about BatchPrint, click **Open Anyway**.
4. Enter your administrator password if asked, then click **Open**.

### Option 3: Open from Finder (macOS 14 and earlier)

1. Open your **Applications** folder in Finder.
2. Control-click or right-click `BatchPrint.app`, then choose **Open**.
3. In the dialog, click **Open** again.

> This Finder shortcut may not work on macOS 26 or 27. If it does not, use Option 1 or Option 2 instead.

### Option 4: Clone and build from source

If you have Xcode Command Line Tools installed, you can build the app yourself:

```sh
git clone https://github.com/gonejack/batchprint.git
cd batchprint
./build.sh
open BatchPrint.app
```

The build creates `BatchPrint.app` in the repository folder; you can drag it into your **Applications** folder. Because it is built locally, it should open without the download warning.

> If `swiftc` is not available, install the command line tools first with `xcode-select --install`.

## Usage

1. Open `BatchPrint.app`.
2. Drop files onto the dashed area, or click it to choose files. After the first batch, drop more files directly onto the file list.
3. Choose the printer, print mode, color mode, and paper size at the bottom of the window.
4. Check the details in the confirmation sheet and click **Start Printing**.
5. The job appears in the system print queue, and a status toast confirms when it has been submitted.

You can also right-click a file in Finder and choose **Open With → BatchPrint**.

## Requirements

- macOS 13.0 or later
- Intel and Apple Silicon
- At least one configured and enabled printer

## Known limitations

- The first launch may show a macOS security warning; see the steps above.
- The available print options depend on the printer. Some printers may reject a job if they do not support the chosen paper size or duplex mode.
- One paper size and one copy (fixed at 1) apply to the whole batch; page ranges, per-file settings, and print previews are not supported.
- All files are submitted as a single print job instead of being queued one by one.
